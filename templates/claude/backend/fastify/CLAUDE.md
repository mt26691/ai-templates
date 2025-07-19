# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this Fastify backend project.

## Project Overview

A high-performance Node.js backend REST API built with Fastify v4+, designed for scalability and maintainability. The project follows:
- Plugin-based architecture for modular design
- Schema-first API development with OpenAPI/Swagger
- TypeScript for type safety
- PostgreSQL with Prisma/TypeORM
- Comprehensive testing with 100% coverage target
- Docker containerization for deployment

## Architecture Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Client Apps   │────▶│   API Gateway   │────▶│  Load Balancer  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                          │
                                ┌─────────────────────────┴─────────────────────────┐
                                │                                                   │
                        ┌───────▼────────┐                                 ┌────────▼───────┐
                        │  Fastify App   │                                 │  Fastify App   │
                        │   Instance 1   │                                 │   Instance 2   │
                        └───────┬────────┘                                 └────────┬───────┘
                                │                                                   │
                        ┌───────▼────────┐                                 ┌────────▼───────┐
                        │    Plugins     │                                 │    Plugins     │
                        │  - Auth        │                                 │  - Auth        │
                        │  - Database    │                                 │  - Database    │
                        │  - Validation  │                                 │  - Validation  │
                        └───────┬────────┘                                 └────────┬───────┘
                                │                                                   │
                        ┌───────▼────────┐                                 ┌────────▼───────┐
                        │    Services    │                                 │    Services    │
                        │  Business Logic│                                 │  Business Logic│
                        └───────┬────────┘                                 └────────┬───────┘
                                │                                                   │
                                └─────────────────┬─────────────────────────────────┘
                                                  │
                                          ┌───────▼────────┐
                                          │   PostgreSQL   │
                                          │   Database     │
                                          │  (Primary)     │
                                          └───────┬────────┘
                                                  │
                                          ┌───────▼────────┐
                                          │     Redis      │
                                          │  Cache/Session │
                                          └────────────────┘
```

## Environment Setup

### Prerequisites
- Node.js 18+ (use nvm for version management)
- PostgreSQL 14+
- Redis 6+
- Docker & Docker Compose
- pnpm (preferred) or npm

### Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd <project-name>

# Install dependencies
pnpm install

# Copy environment file
cp .env.example .env

# Start development dependencies
docker-compose up -d postgres redis

# Run database migrations
pnpm db:migrate

# Seed database (development only)
pnpm db:seed

# Start development server
pnpm dev
```

### Environment Files
- `.env.example` - Template with all required variables
- `.env` - Local development (gitignored)
- `.env.test` - Test environment
- `.env.production` - Production (managed by CI/CD)

## Environment Variable Validation

**CRITICAL**: Never access `process.env.VARIABLE` directly. Always use the validated config from `src/config/env.ts`.

### Implementation
```typescript
// src/config/env.ts
import { z } from 'zod'

const envSchema = z.object({
  // Node environment
  NODE_ENV: z.enum(['development', 'test', 'production']),
  
  // Server
  PORT: z.string().regex(/^\d+$/).transform(Number),
  HOST: z.string().default('0.0.0.0'),
  
  // Database
  DATABASE_URL: z.string().url(),
  DATABASE_POOL_MIN: z.string().regex(/^\d+$/).transform(Number),
  DATABASE_POOL_MAX: z.string().regex(/^\d+$/).transform(Number),
  
  // Redis
  REDIS_URL: z.string().url(),
  
  // Auth
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string(),
  
  // API Keys
  API_KEY: z.string().min(1),
  
  // Features
  ENABLE_SWAGGER: z.string().transform(val => val === 'true'),
  RATE_LIMIT_MAX: z.string().regex(/^\d+$/).transform(Number),
})

// Validate at startup - fail fast!
const parsed = envSchema.safeParse(process.env)

if (!parsed.success) {
  console.error('❌ Invalid environment variables:')
  console.error(parsed.error.flatten().fieldErrors)
  process.exit(1)
}

export const env = parsed.data

// Usage in code
import { env } from '@/config/env'
const port = env.PORT // Type-safe and validated
```

### No Default Values Policy
- **Never use default values in Zod schema** (except for computed values)
- **Fail fast** if required variables are missing
- This prevents silent failures in production

## Directory Structure

```
src/
├── config/                 # All configuration files
│   ├── env.ts             # Environment validation (CRITICAL)
│   ├── database.ts        # Database configuration
│   ├── redis.ts           # Redis configuration
│   ├── swagger.ts         # OpenAPI/Swagger config
│   └── cors.ts            # CORS configuration
├── plugins/               # Fastify plugins (load order matters!)
│   ├── 00-env.ts         # Load environment first
│   ├── 01-security.ts    # Security headers
│   ├── 02-database.ts    # Database connection
│   ├── 03-redis.ts       # Redis connection
│   ├── 04-auth.ts        # Authentication
│   └── 05-swagger.ts     # API documentation
├── routes/                # API routes
│   ├── v1/               # API version 1
│   │   ├── users/
│   │   ├── auth/
│   │   └── index.ts
│   └── health/           # Health checks
├── schemas/              # Validation schemas
│   ├── common/           # Shared schemas
│   ├── requests/         # Request schemas
│   └── responses/        # Response schemas
├── services/             # Business logic
│   ├── user.service.ts
│   └── auth.service.ts
├── repositories/         # Data access layer
│   ├── user.repository.ts
│   └── base.repository.ts
├── utils/                # Pure utility functions
│   ├── crypto.ts         # Crypto utilities
│   ├── date.ts           # Date helpers
│   ├── validation.ts     # Validation helpers
│   └── errors.ts         # Error classes
├── types/                # TypeScript types
│   ├── fastify.d.ts      # Fastify augmentation
│   └── index.d.ts
├── hooks/                # Lifecycle hooks
│   ├── auth.hook.ts
│   └── error.hook.ts
└── tests/                # Test files
    ├── unit/
    ├── integration/
    └── fixtures/
```

### Directory Guidelines

#### `/src/config` - Configuration Management
- Central location for ALL configuration
- Each config file exports typed, validated configuration
- No configuration logic outside this directory
- Example:
```typescript
// src/config/database.ts
import { env } from './env'

export const databaseConfig = {
  url: env.DATABASE_URL,
  pool: {
    min: env.DATABASE_POOL_MIN,
    max: env.DATABASE_POOL_MAX,
  }
}
```

#### `/src/utils` - Pure Functions Only
- **MUST be pure functions** (no side effects)
- **MUST have 100% test coverage**
- No database access, no API calls
- Reusable across the application
- Example:
```typescript
// src/utils/crypto.ts
export function hashPassword(password: string, salt: string): string {
  // Pure function - same input always produces same output
  return crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512').toString('hex')
}
```

## Branch Naming Convention

### Format: `type/scope-description`

- **feature/** - New features (e.g., `feature/user-authentication`)
- **fix/** - Bug fixes (e.g., `fix/login-validation`)
- **refactor/** - Code refactoring (e.g., `refactor/service-layer`)
- **docs/** - Documentation (e.g., `docs/api-endpoints`)
- **test/** - Test additions (e.g., `test/user-service`)
- **chore/** - Maintenance (e.g., `chore/update-dependencies`)

### Rules
- Use lowercase only
- Separate words with hyphens
- Keep under 50 characters
- Include ticket number if applicable (e.g., `feature/JIRA-123-user-profile`)

## API Schema & OpenAPI

**MANDATORY**: Every endpoint MUST have complete OpenAPI documentation. No exceptions.

### Implementation
```typescript
// src/routes/v1/users/create.ts
export const createUserSchema = {
  summary: 'Create a new user',
  description: 'Creates a new user account with the provided information',
  tags: ['users'],
  body: Type.Object({
    email: Type.String({ format: 'email' }),
    password: Type.String({ minLength: 8 }),
    name: Type.String({ minLength: 2 })
  }),
  response: {
    201: Type.Object({
      user: UserSchema,
      message: Type.String()
    }),
    400: ErrorSchema,
    409: ErrorSchema
  }
}

// Route implementation
fastify.post('/users', {
  schema: createUserSchema,
  preHandler: [validateApiKey]
}, async (request, reply) => {
  // Implementation
})
```

### Swagger UI
- Development: http://localhost:3000/documentation
- Auto-generated from schemas
- Test endpoints directly from UI

## Validation Schema

**MANDATORY**: Every endpoint MUST validate:
1. Request body
2. Query parameters
3. Path parameters
4. Response data

### Example
```typescript
// src/schemas/requests/user.ts
export const CreateUserBody = Type.Object({
  email: Type.String({ 
    format: 'email',
    examples: ['user@example.com']
  }),
  password: Type.String({ 
    minLength: 8,
    pattern: '^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).+$'
  }),
  name: Type.String({ 
    minLength: 2,
    maxLength: 100 
  })
})

// Use in route
const schema = {
  body: CreateUserBody,
  querystring: Type.Object({
    includeProfile: Type.Optional(Type.Boolean())
  }),
  params: Type.Object({
    id: Type.String({ format: 'uuid' })
  })
}
```

## CORS Configuration

```typescript
// src/config/cors.ts
import { env } from './env'

export const corsConfig = {
  origin: (origin: string, callback: Function) => {
    const allowedOrigins = env.ALLOWED_ORIGINS.split(',')
    
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true)
    } else {
      callback(new Error('Not allowed by CORS'))
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
}

// Usage in plugin
await fastify.register(cors, corsConfig)
```

## Dockerfile Optimization

```dockerfile
# Multi-stage build for optimization
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files
COPY package*.json pnpm-lock.yaml ./

# Install dependencies
RUN npm install -g pnpm && pnpm install --frozen-lockfile

# Copy source
COPY . .

# Build application
RUN pnpm build

# Production stage
FROM node:18-alpine

RUN apk add --no-cache tini

WORKDIR /app

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Use non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node dist/health-check.js

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/server.js"]
```

## Monitoring & Health Checks

### Health Check Endpoints
```typescript
// src/routes/health/index.ts
export default async function (fastify: FastifyInstance) {
  // Basic health check
  fastify.get('/health', {
    schema: {
      response: {
        200: Type.Object({
          status: Type.Literal('ok'),
          timestamp: Type.String()
        })
      }
    }
  }, async () => ({
    status: 'ok',
    timestamp: new Date().toISOString()
  }))

  // Detailed health check
  fastify.get('/health/ready', async (request, reply) => {
    const checks = {
      database: 'ok',
      redis: 'ok',
      timestamp: new Date().toISOString()
    }

    try {
      // Check database
      await fastify.db.$queryRaw`SELECT 1`
    } catch {
      checks.database = 'error'
    }

    try {
      // Check Redis
      await fastify.redis.ping()
    } catch {
      checks.redis = 'error'
    }

    const isHealthy = Object.values(checks).every(v => v === 'ok' || v.includes('T'))
    
    reply.code(isHealthy ? 200 : 503).send(checks)
  })
}
```

## Testing

### Test Containers for PostgreSQL
```typescript
// tests/helpers/database.ts
import { PostgreSqlContainer } from '@testcontainers/postgresql'

let container: StartedPostgreSqlContainer

export async function setupTestDatabase() {
  container = await new PostgreSqlContainer()
    .withDatabase('testdb')
    .withUsername('testuser')
    .withPassword('testpass')
    .start()

  process.env.DATABASE_URL = container.getConnectionUri()
  
  // Run migrations
  await runMigrations()
}

export async function teardownTestDatabase() {
  await container.stop()
}
```

### Integration Test Example
```typescript
// tests/integration/users.test.ts
describe('User API', () => {
  let app: FastifyInstance

  beforeAll(async () => {
    await setupTestDatabase()
    app = await buildApp({ logger: false })
  })

  afterAll(async () => {
    await app.close()
    await teardownTestDatabase()
  })

  describe('POST /users', () => {
    it('should create a user', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/v1/users',
        payload: {
          email: 'test@example.com',
          password: 'Password123!',
          name: 'Test User'
        }
      })

      expect(response.statusCode).toBe(201)
      expect(response.json()).toMatchObject({
        user: {
          email: 'test@example.com',
          name: 'Test User'
        }
      })
    })
  })
})
```

### Test Coverage Requirements
- **Overall**: 100% coverage target
- **Pure functions** (utils/): 100% mandatory
- **Services**: 95%+ coverage
- **Routes**: Integration tests required

### Coverage Configuration
```json
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      branches: 100,
      functions: 100,
      lines: 100,
      statements: 100
    },
    './src/utils/': {
      branches: 100,
      functions: 100,
      lines: 100,
      statements: 100
    }
  }
}
```

## Common Commands

### Development
```bash
npm run dev          # Start development server with hot reload
npm run build        # Compile TypeScript to JavaScript
npm run start        # Start production server
npm run lint         # Run ESLint
npm run format       # Format code with Prettier
```

### Testing
```bash
npm test             # Run all tests
npm run test:unit    # Run unit tests only
npm run test:e2e     # Run integration tests
npm run test:watch   # Run tests in watch mode
npm run test:cov     # Generate coverage report
```

### Database
```bash
npm run db:migrate         # Run database migrations
npm run db:migrate:undo    # Rollback last migration
npm run db:seed            # Seed database with test data
npm run db:reset           # Reset database (drop, create, migrate, seed)
```

## Architecture and Structure

### Plugin-Based Architecture
Fastify uses a plugin system where everything is a plugin. This provides:
- Encapsulation and dependency management
- Reusable components
- Clear separation of concerns
- Automatic loading with @fastify/autoload

### Directory Structure
```
src/
├── app.ts                 # Application factory
├── server.ts             # Server entry point
├── config/               # Configuration files
│   ├── env.ts           # Environment validation
│   └── database.ts      # Database config
├── plugins/              # Core plugins (order matters!)
│   ├── env.ts           # Environment plugin (loads first)
│   ├── database.ts      # Database connection
│   ├── auth.ts          # Authentication setup
│   └── swagger.ts       # API documentation
├── routes/               # Route definitions
│   ├── v1/              # API version 1
│   │   ├── users/       # User routes
│   │   ├── auth/        # Auth routes
│   │   └── index.ts     # Route autoloader
│   └── health.ts        # Health check
├── schemas/              # JSON schemas
│   ├── common.ts        # Shared schemas
│   ├── user.ts          # User schemas
│   └── auth.ts          # Auth schemas
├── services/             # Business logic
│   ├── user.service.ts
│   └── auth.service.ts
├── models/               # Database models
│   ├── user.model.ts
│   └── index.ts
├── hooks/                # Lifecycle hooks
│   ├── auth.ts          # Auth hooks
│   └── error.ts         # Error handling
├── decorators/           # Custom decorators
│   └── index.ts
├── utils/                # Utilities
│   ├── errors.ts        # Custom errors
│   └── logger.ts        # Logger setup
└── types/                # TypeScript types
    ├── fastify.d.ts     # Fastify augmentation
    └── index.d.ts       # Shared types
```

## Key Implementation Patterns

### 1. Schema-First Route Definition
```typescript
// Always define schemas for validation
const schema = {
  body: Type.Object({
    email: Type.String({ format: 'email' }),
    password: Type.String({ minLength: 8 })
  }),
  response: {
    200: Type.Object({
      user: UserSchema,
      token: Type.String()
    })
  }
}

// Use in route
fastify.post('/login', { schema }, async (request, reply) => {
  // Handler implementation
})
```

### 2. Plugin Registration Order
```typescript
// app.ts - Order matters!
export async function buildApp(opts: FastifyServerOptions = {}) {
  const app = fastify(opts)
  
  // 1. Core plugins first
  await app.register(envPlugin)
  await app.register(corsPlugin)
  await app.register(helmetPlugin)
  
  // 2. Database and auth
  await app.register(databasePlugin)
  await app.register(authPlugin)
  
  // 3. Application plugins
  await app.register(servicesPlugin)
  
  // 4. Routes last
  await app.register(autoload, {
    dir: join(__dirname, 'routes'),
    options: { prefix: '/api' }
  })
  
  return app
}
```

### 3. Service Layer Pattern
```typescript
// Always use services for business logic
export class UserService {
  constructor(private fastify: FastifyInstance) {}
  
  async createUser(data: CreateUserDto): Promise<User> {
    const user = await this.fastify.db.user.create({
      data: {
        ...data,
        password: await hash(data.password)
      }
    })
    
    return user
  }
}
```

### 4. Error Handling
```typescript
// Use custom errors
export class ValidationError extends Error {
  statusCode = 400
  constructor(message: string, public details?: any) {
    super(message)
  }
}

// Global error handler
app.setErrorHandler((error, request, reply) => {
  const { statusCode = 500, message, details } = error
  
  request.log.error({ error, request: request.raw }, 'Request failed')
  
  reply.status(statusCode).send({
    error: {
      message,
      details,
      statusCode,
      timestamp: new Date().toISOString()
    }
  })
})
```

## Testing Best Practices

### Integration Testing
```typescript
// Use fastify.inject() for route testing
const app = await buildApp({ logger: false })

const response = await app.inject({
  method: 'POST',
  url: '/api/users',
  payload: { email: 'test@example.com' }
})

expect(response.statusCode).toBe(201)
```

### Test Database
- Use separate test database
- Run migrations before tests
- Use transactions for isolation
- Clean up after each test

## Performance Optimization

1. **Use JSON Schema Serialization**: Fastify's schema-based serialization is 2x faster
2. **Enable Production Mode**: Set NODE_ENV=production
3. **Use Clustering**: PM2 or Node.js cluster module
4. **Implement Caching**: Redis for session/cache data
5. **Database Optimization**: 
   - Connection pooling
   - Query optimization
   - Proper indexing

## Security Checklist

- [ ] Input validation with JSON schemas
- [ ] JWT authentication properly configured
- [ ] Rate limiting enabled
- [ ] CORS configured correctly
- [ ] Helmet for security headers
- [ ] SQL injection prevention
- [ ] Environment variables validated
- [ ] HTTPS in production
- [ ] Dependency vulnerabilities checked

## Database Integration

### Using Prisma
```typescript
// plugins/database.ts
export default fp(async (fastify) => {
  const prisma = new PrismaClient({
    log: fastify.log.level === 'debug' ? ['query'] : []
  })
  
  await prisma.$connect()
  
  fastify.decorate('db', prisma)
  fastify.addHook('onClose', async () => {
    await prisma.$disconnect()
  })
})
```

### Using TypeORM
```typescript
// Alternative with TypeORM
const connection = await createConnection({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  entities: [User, Post],
  synchronize: false // Never in production!
})

fastify.decorate('db', connection)
```

## API Documentation

Swagger/OpenAPI documentation is auto-generated from schemas:
- Development: http://localhost:3000/documentation
- Static generation: `npm run docs:generate`

## Deployment Checklist

1. **Environment Setup**
   - All environment variables configured
   - Production database ready
   - Redis/cache configured

2. **Build Process**
   - TypeScript compiled
   - Dependencies optimized
   - Source maps configured

3. **Process Management**
   - PM2 ecosystem file configured
   - Graceful shutdown implemented
   - Health checks working

4. **Monitoring**
   - Logging configured (Pino)
   - APM tool integrated
   - Alerts configured

## Common Pitfalls to Avoid

1. **Don't use `reply.send()` with `return`** - Use one or the other
2. **Don't forget `await` with `register()`** - Plugins are async
3. **Don't mutate request/reply objects** - Use decorators instead
4. **Don't use synchronous operations** - Everything should be async
5. **Don't skip schema validation** - Always validate input/output

## Debugging Tips

1. Enable debug logging: `LOG_LEVEL=debug npm run dev`
2. Use Fastify's built-in logger: `request.log.info({ data }, 'Message')`
3. Check plugin registration order if decorators are undefined
4. Use `fastify.printRoutes()` to debug routing issues
5. Enable Prisma query logging in development

## Additional Resources

- [Fastify Documentation](https://www.fastify.io/)
- [TypeScript Fastify Guide](https://www.fastify.io/docs/latest/TypeScript/)
- [Fastify Best Practices](https://www.fastify.io/docs/latest/Guides/Index/)
- Project-specific docs in `/docs` directory