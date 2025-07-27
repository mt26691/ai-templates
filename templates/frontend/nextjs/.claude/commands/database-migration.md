# Database Migration Guide - Frontend (Next.js)

This command helps you manage database schema changes safely and efficiently.

## Step 1: Migration Setup

### Install Migration Tools
```bash
# For SQL databases (PostgreSQL/MySQL)
npm install --save knex
npm install --save-dev @types/knex

# Database drivers
npm install --save pg           # PostgreSQL
npm install --save mysql2       # MySQL
npm install --save better-sqlite3  # SQLite

# For MongoDB
npm install --save migrate-mongo
```

### Configure Knex
```javascript
// knexfile.js
module.exports = {
  development: {
    client: 'postgresql',
    connection: {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'myapp_dev',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD
    },
    pool: {
      min: 2,
      max: 10
    },
    migrations: {
      directory: './migrations',
      tableName: 'knex_migrations',
      extension: 'ts'
    },
    seeds: {
      directory: './seeds'
    }
  },
  staging: {
    client: 'postgresql',
    connection: process.env.DATABASE_URL,
    migrations: {
      directory: './migrations',
      tableName: 'knex_migrations'
    }
  },
  production: {
    client: 'postgresql',
    connection: {
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false }
    },
    pool: {
      min: 2,
      max: 10
    },
    migrations: {
      directory: './migrations',
      tableName: 'knex_migrations'
    }
  }
};
```

## Step 2: Create Migrations

### Generate Migration File
```bash
# Create new migration
npx knex migrate:make create_users_table

# With timestamp prefix
npx knex migrate:make add_email_verification --timestamp

# TypeScript migration
npx knex migrate:make create_orders_table --ts
```

### Migration File Structure
```typescript
// migrations/20240101120000_create_users_table.ts
import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // Create users table
  await knex.schema.createTable('users', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('email', 255).notNullable().unique();
    table.string('password_hash', 255).notNullable();
    table.string('name', 100).notNullable();
    table.enum('role', ['user', 'admin']).defaultTo('user');
    table.boolean('email_verified').defaultTo(false);
    table.timestamp('email_verified_at').nullable();
    table.jsonb('metadata').defaultTo('{}');
    table.timestamps(true, true); // created_at, updated_at
    
    // Indexes
    table.index('email');
    table.index('created_at');
    table.index(['role', 'created_at']);
  });

  // Create trigger for updated_at
  await knex.raw(`
    CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);
}

export async function down(knex: Knex): Promise<void> {
  await knex.raw('DROP TRIGGER IF EXISTS update_users_updated_at ON users');
  await knex.schema.dropTable('users');
}
```

### Complex Migration Examples

#### Adding Columns
```typescript
export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.string('phone_number', 20).nullable();
    table.date('date_of_birth').nullable();
    table.string('timezone', 50).defaultTo('UTC');
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.dropColumn('phone_number');
    table.dropColumn('date_of_birth');
    table.dropColumn('timezone');
  });
}
```

#### Data Migration
```typescript
export async function up(knex: Knex): Promise<void> {
  // Add new column
  await knex.schema.alterTable('users', (table) => {
    table.string('display_name', 100).nullable();
  });

  // Migrate data
  const users = await knex('users').select('id', 'first_name', 'last_name');
  
  for (const user of users) {
    await knex('users')
      .where('id', user.id)
      .update({
        display_name: `${user.first_name} ${user.last_name}`.trim()
      });
  }

  // Make column required after data migration
  await knex.schema.alterTable('users', (table) => {
    table.string('display_name', 100).notNullable().alter();
  });

  // Drop old columns
  await knex.schema.alterTable('users', (table) => {
    table.dropColumn('first_name');
    table.dropColumn('last_name');
  });
}
```

## Step 3: Running Migrations

### Migration Commands
```bash
# Run pending migrations
npx knex migrate:latest

# Run migrations up to specific batch
npx knex migrate:up

# Rollback last batch
npx knex migrate:rollback

# Rollback all migrations
npx knex migrate:rollback --all

# Get migration status
npx knex migrate:status

# List completed migrations
npx knex migrate:list

# Run specific migration
npx knex migrate:up 20240101120000_create_users_table.ts
```

### Environment-Specific Migrations
```bash
# Development
NODE_ENV=development npx knex migrate:latest

# Staging
NODE_ENV=staging npx knex migrate:latest

# Production (be careful!)
NODE_ENV=production npx knex migrate:latest
```

## Step 4: Zero-Downtime Migrations

### Safe Migration Patterns

#### Adding Nullable Columns
```typescript
// Safe: Add nullable column first
export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('orders', (table) => {
    table.decimal('tax_amount', 10, 2).nullable();
  });
}

// Later migration: Populate and make required
export async function up(knex: Knex): Promise<void> {
  // Calculate and populate tax_amount
  await knex.raw(`
    UPDATE orders 
    SET tax_amount = total_amount * 0.08 
    WHERE tax_amount IS NULL
  `);

  // Make column required
  await knex.schema.alterTable('orders', (table) => {
    table.decimal('tax_amount', 10, 2).notNullable().alter();
  });
}
```

#### Renaming Columns (Two-Phase)
```typescript
// Phase 1: Add new column and sync data
export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('users', (table) => {
    table.string('username', 50).nullable();
  });

  // Copy data
  await knex.raw('UPDATE users SET username = login_name');

  // Add trigger to keep in sync
  await knex.raw(`
    CREATE TRIGGER sync_username_to_login_name
    BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_columns('username', 'login_name');
  `);
}

// Phase 2: Remove old column (after code deployment)
export async function up(knex: Knex): Promise<void> {
  await knex.raw('DROP TRIGGER sync_username_to_login_name ON users');
  
  await knex.schema.alterTable('users', (table) => {
    table.dropColumn('login_name');
  });
}
```

## Step 5: Migration Testing

### Test Migration Files
```typescript
// tests/migrations/20240101120000_create_users_table.test.ts
import { Knex } from 'knex';
import { createTestDb, destroyTestDb } from '../helpers';

describe('Create Users Table Migration', () => {
  let db: Knex;

  beforeEach(async () => {
    db = await createTestDb();
  });

  afterEach(async () => {
    await destroyTestDb(db);
  });

  it('should create users table with correct schema', async () => {
    // Run migration
    await db.migrate.up();

    // Check table exists
    const hasTable = await db.schema.hasTable('users');
    expect(hasTable).toBe(true);

    // Check columns
    const columns = await db('users').columnInfo();
    expect(columns).toHaveProperty('id');
    expect(columns).toHaveProperty('email');
    expect(columns).toHaveProperty('created_at');
  });

  it('should rollback cleanly', async () => {
    await db.migrate.up();
    await db.migrate.down();

    const hasTable = await db.schema.hasTable('users');
    expect(hasTable).toBe(false);
  });
});
```

### Performance Testing
```typescript
// Test migration performance on large datasets
export async function testMigrationPerformance(knex: Knex) {
  console.time('Migration Performance');

  // Create test data
  const testData = Array.from({ length: 100000 }, (_, i) => ({
    email: `test${i}@example.com`,
    name: `Test User ${i}`
  }));

  await knex.batchInsert('users', testData, 1000);

  // Run migration
  console.time('Actual Migration');
  await knex.migrate.up();
  console.timeEnd('Actual Migration');

  // Verify data integrity
  const count = await knex('users').count('id').first();
  console.log(`Records after migration: ${count}`);

  console.timeEnd('Migration Performance');
}
```

## Step 6: Database Backup and Recovery

### Pre-Migration Backup
```bash
#!/bin/bash
# backup-before-migration.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME=${DB_NAME:-myapp}
BACKUP_DIR="./backups"

mkdir -p $BACKUP_DIR

echo "Creating backup before migration..."

# PostgreSQL
pg_dump $DATABASE_URL > "$BACKUP_DIR/pre_migration_${TIMESTAMP}.sql"

# MySQL
# mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > "$BACKUP_DIR/pre_migration_${TIMESTAMP}.sql"

# Compress backup
gzip "$BACKUP_DIR/pre_migration_${TIMESTAMP}.sql"

echo "Backup created: $BACKUP_DIR/pre_migration_${TIMESTAMP}.sql.gz"
```

### Rollback with Restore
```bash
#!/bin/bash
# rollback-with-restore.sh

if [ -z "$1" ]; then
  echo "Usage: ./rollback-with-restore.sh <backup-file>"
  exit 1
fi

BACKUP_FILE=$1

echo "Rolling back database..."

# Drop existing database
psql $DATABASE_URL -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql $DATABASE_URL -c "CREATE DATABASE $DB_NAME;"

# Restore from backup
gunzip -c $BACKUP_FILE | psql $DATABASE_URL

echo "Database restored from: $BACKUP_FILE"
```

## Step 7: Migration Documentation

### Migration Log Template
```markdown
# Migration: Add User Preferences Table

**Date**: 2024-01-15
**Author**: John Doe
**Ticket**: JIRA-1234

## Purpose
Add user preferences table to store user-specific settings.

## Changes
1. Create `user_preferences` table
2. Add foreign key to `users` table
3. Create indexes for performance

## Rollback Plan
```sql
DROP TABLE IF EXISTS user_preferences;
```

## Testing
- [x] Migration runs successfully
- [x] Rollback works correctly
- [x] Performance impact acceptable
- [x] No breaking changes

## Notes
- Default preferences are set via application code
- Migration takes ~2 seconds on staging (1M users)
```

## Step 8: Migration Monitoring

### Add Migration Metrics
```typescript
// src/migrations/metrics.ts
export async function trackMigration(
  name: string,
  fn: () => Promise<void>
): Promise<void> {
  const start = Date.now();
  
  try {
    console.log(`Starting migration: ${name}`);
    await fn();
    
    const duration = Date.now() - start;
    console.log(`Migration completed: ${name} (${duration}ms)`);
    
    // Send metrics
    await sendMetric('migration.success', {
      name,
      duration,
      environment: process.env.NODE_ENV
    });
  } catch (error) {
    const duration = Date.now() - start;
    console.error(`Migration failed: ${name}`, error);
    
    await sendMetric('migration.failure', {
      name,
      duration,
      error: error.message,
      environment: process.env.NODE_ENV
    });
    
    throw error;
  }
}
```

## Step 9: CI/CD Integration

### GitHub Actions Migration Check
```yaml
# .github/workflows/migration-check.yml
name: Migration Check

on:
  pull_request:
    paths:
      - 'migrations/**'

jobs:
  test-migrations:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: 18
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run migrations
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost/test
      run: |
        npx knex migrate:latest
        npx knex migrate:rollback --all
        npx knex migrate:latest
    
    - name: Test migration performance
      run: npm run test:migrations
```

## Step 10: Production Migration Checklist

```markdown
## Production Migration Checklist

### Pre-Migration
- [ ] Migration tested on staging
- [ ] Rollback script prepared
- [ ] Database backup created
- [ ] Team notified of maintenance window
- [ ] Migration time estimated

### Migration Execution
- [ ] Application in maintenance mode (if required)
- [ ] Migration command executed
- [ ] Migration verified with status check
- [ ] Quick smoke test performed
- [ ] Application taken out of maintenance mode

### Post-Migration
- [ ] Application functionality verified
- [ ] Performance metrics checked
- [ ] Error rates monitored
- [ ] Database queries performing well
- [ ] Migration documented in changelog

### Rollback Criteria
- [ ] Migration takes longer than expected (>5 minutes)
- [ ] Application errors spike after migration
- [ ] Database performance degrades
- [ ] Data integrity issues detected

### Emergency Contacts
- Database Admin: @dba-team
- DevOps Lead: @devops-lead
- Product Owner: @product-owner
```

## Common Migration Patterns

### 1. Adding Indexes Without Downtime
```sql
-- PostgreSQL: Create index concurrently
CREATE INDEX CONCURRENTLY idx_users_email_created 
ON users(email, created_at);

-- MySQL: Use pt-online-schema-change
pt-online-schema-change --alter "ADD INDEX idx_email_created (email, created_at)" D=mydb,t=users
```

### 2. Large Table Alterations
```typescript
// Batch processing for large updates
export async function up(knex: Knex): Promise<void> {
  const batchSize = 1000;
  let offset = 0;
  
  while (true) {
    const batch = await knex('large_table')
      .select('id')
      .orderBy('id')
      .limit(batchSize)
      .offset(offset);
    
    if (batch.length === 0) break;
    
    await knex('large_table')
      .whereIn('id', batch.map(r => r.id))
      .update({ new_column: knex.raw('old_column * 1.1') });
    
    offset += batchSize;
    
    // Prevent overwhelming the database
    await new Promise(resolve => setTimeout(resolve, 100));
  }
}
```