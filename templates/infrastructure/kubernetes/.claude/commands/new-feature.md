# New Feature Development - Backend (Fastify)

This command guides you through developing new features following best practices and ensuring comprehensive implementation.

## Step 1: Feature Planning

### Create Feature Specification
```bash
# Create feature documentation
mkdir -p docs/features/<feature-name>
touch docs/features/<feature-name>/specification.md
```

Feature specification template:
```markdown
# Feature: <Feature Name>

## Overview
Brief description of the feature and its business value.

## User Stories
- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Requirements
### API Endpoints
- POST /api/v1/resource - Create resource
- GET /api/v1/resource/:id - Get resource
- PUT /api/v1/resource/:id - Update resource
- DELETE /api/v1/resource/:id - Delete resource

### Data Models
- Resource schema
- Validation rules
- Relationships

### Business Logic
- Core functionality
- Edge cases
- Error handling

## Non-Functional Requirements
- Performance: < 200ms response time
- Security: Authentication required
- Scalability: Support 1000 concurrent users
```

## Step 2: Create Feature Branch

```bash
# Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/<feature-name>

# Example
git checkout -b feature/user-notifications
```

## Step 3: Database Schema Design

### Create Migration
```bash
# Generate migration file
npm run migrate:make <feature-name>

# Example
npm run migrate:make add_notifications_table
```

Example migration:
```typescript
export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('notifications', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users');
    table.string('type').notNullable();
    table.string('title').notNullable();
    table.text('message').notNullable();
    table.jsonb('metadata');
    table.boolean('is_read').defaultTo(false);
    table.timestamp('read_at');
    table.timestamps(true, true);
    
    table.index(['user_id', 'is_read']);
    table.index('created_at');
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTable('notifications');
}
```

### Run Migration
```bash
# Run migration
npm run migrate:latest

# Verify migration
npm run migrate:status
```

## Step 4: Model Implementation

### Create Model
```bash
# Create model file
touch src/models/notification.model.ts
```

Example model:
```typescript
// src/models/notification.model.ts
import { z } from 'zod';

export const NotificationSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  type: z.enum(['info', 'warning', 'error', 'success']),
  title: z.string().min(1).max(255),
  message: z.string().min(1),
  metadata: z.record(z.any()).optional(),
  isRead: z.boolean().default(false),
  readAt: z.date().nullable().optional(),
  createdAt: z.date(),
  updatedAt: z.date()
});

export type Notification = z.infer<typeof NotificationSchema>;

export const CreateNotificationSchema = NotificationSchema.omit({
  id: true,
  isRead: true,
  readAt: true,
  createdAt: true,
  updatedAt: true
});

export type CreateNotification = z.infer<typeof CreateNotificationSchema>;
```

## Step 5: Service Layer Implementation

### Create Service
```bash
# Create service file
touch src/services/notification.service.ts
```

Example service:
```typescript
// src/services/notification.service.ts
import { FastifyInstance } from 'fastify';
import { Notification, CreateNotification } from '../models/notification.model';

export class NotificationService {
  constructor(private fastify: FastifyInstance) {}

  async create(data: CreateNotification): Promise<Notification> {
    const notification = await this.fastify.db('notifications')
      .insert(data)
      .returning('*')
      .then(rows => rows[0]);
    
    // Emit real-time event
    await this.fastify.io.to(`user:${data.userId}`).emit('notification', notification);
    
    return notification;
  }

  async findByUser(userId: string, filters?: {
    isRead?: boolean;
    limit?: number;
    offset?: number;
  }): Promise<Notification[]> {
    let query = this.fastify.db('notifications')
      .where('user_id', userId)
      .orderBy('created_at', 'desc');
    
    if (filters?.isRead !== undefined) {
      query = query.where('is_read', filters.isRead);
    }
    
    if (filters?.limit) {
      query = query.limit(filters.limit);
    }
    
    if (filters?.offset) {
      query = query.offset(filters.offset);
    }
    
    return query;
  }

  async markAsRead(id: string, userId: string): Promise<Notification> {
    const notification = await this.fastify.db('notifications')
      .where({ id, user_id: userId })
      .update({ is_read: true, read_at: new Date() })
      .returning('*')
      .then(rows => rows[0]);
    
    if (!notification) {
      throw new Error('Notification not found');
    }
    
    return notification;
  }
}
```

## Step 6: Route Implementation

### Create Route
```bash
# Create route file
touch src/routes/notifications/index.ts
```

Example route:
```typescript
// src/routes/notifications/index.ts
import { FastifyPluginAsync } from 'fastify';
import { NotificationService } from '../../services/notification.service';
import { CreateNotificationSchema } from '../../models/notification.model';

const notificationRoutes: FastifyPluginAsync = async (fastify) => {
  const service = new NotificationService(fastify);

  // Get notifications for authenticated user
  fastify.get('/', {
    onRequest: [fastify.authenticate],
    schema: {
      querystring: {
        type: 'object',
        properties: {
          isRead: { type: 'boolean' },
          limit: { type: 'number', minimum: 1, maximum: 100, default: 20 },
          offset: { type: 'number', minimum: 0, default: 0 }
        }
      }
    }
  }, async (request, reply) => {
    const notifications = await service.findByUser(
      request.user.id,
      request.query
    );
    return { data: notifications };
  });

  // Create notification (admin only)
  fastify.post('/', {
    onRequest: [fastify.authenticate, fastify.requireRole('admin')],
    schema: {
      body: CreateNotificationSchema
    }
  }, async (request, reply) => {
    const notification = await service.create(request.body);
    reply.code(201).send({ data: notification });
  });

  // Mark notification as read
  fastify.patch('/:id/read', {
    onRequest: [fastify.authenticate]
  }, async (request, reply) => {
    const notification = await service.markAsRead(
      request.params.id,
      request.user.id
    );
    return { data: notification };
  });
};

export default notificationRoutes;
```

### Register Route
```typescript
// src/app.ts
app.register(notificationRoutes, { prefix: '/api/v1/notifications' });
```

## Step 7: Testing Implementation

### Unit Tests
```bash
# Create test files
touch tests/unit/services/notification.service.test.ts
touch tests/unit/models/notification.model.test.ts
```

Example unit test:
```typescript
// tests/unit/services/notification.service.test.ts
import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { NotificationService } from '../../../src/services/notification.service';

describe('NotificationService', () => {
  let service: NotificationService;
  let mockFastify: any;

  beforeEach(() => {
    mockFastify = {
      db: jest.fn(),
      io: { to: jest.fn(() => ({ emit: jest.fn() })) }
    };
    service = new NotificationService(mockFastify);
  });

  describe('create', () => {
    it('should create a notification', async () => {
      const mockNotification = {
        id: 'uuid',
        userId: 'user-uuid',
        type: 'info',
        title: 'Test',
        message: 'Test message'
      };

      mockFastify.db.mockReturnValue({
        insert: jest.fn().mockReturnValue({
          returning: jest.fn().mockResolvedValue([mockNotification])
        })
      });

      const result = await service.create({
        userId: 'user-uuid',
        type: 'info',
        title: 'Test',
        message: 'Test message'
      });

      expect(result).toEqual(mockNotification);
      expect(mockFastify.io.to).toHaveBeenCalledWith('user:user-uuid');
    });
  });
});
```

### Integration Tests
```bash
# Create integration test
touch tests/integration/notifications.test.ts
```

Example integration test:
```typescript
// tests/integration/notifications.test.ts
import { build } from '../helper';

describe('Notifications API', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await build();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /api/v1/notifications', () => {
    it('should return user notifications', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/api/v1/notifications',
        headers: {
          authorization: 'Bearer valid-token'
        }
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toHaveProperty('data');
      expect(Array.isArray(response.json().data)).toBe(true);
    });

    it('should require authentication', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/api/v1/notifications'
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
```

## Step 8: API Documentation

### Update OpenAPI Schema
```yaml
# docs/openapi.yaml
paths:
  /api/v1/notifications:
    get:
      summary: Get user notifications
      tags:
        - Notifications
      security:
        - bearerAuth: []
      parameters:
        - name: isRead
          in: query
          schema:
            type: boolean
        - name: limit
          in: query
          schema:
            type: number
            minimum: 1
            maximum: 100
            default: 20
        - name: offset
          in: query
          schema:
            type: number
            minimum: 0
            default: 0
      responses:
        '200':
          description: List of notifications
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Notification'
```

## Step 9: Feature Flag Implementation (Optional)

```typescript
// src/config/features.ts
export const features = {
  notifications: {
    enabled: process.env.FEATURE_NOTIFICATIONS === 'true',
    realtime: process.env.FEATURE_NOTIFICATIONS_REALTIME === 'true'
  }
};

// In route registration
if (features.notifications.enabled) {
  app.register(notificationRoutes, { prefix: '/api/v1/notifications' });
}
```

## Step 10: Performance Optimization

### Add Caching
```typescript
// src/services/notification.service.ts
async findByUser(userId: string, filters?: any): Promise<Notification[]> {
  const cacheKey = `notifications:${userId}:${JSON.stringify(filters)}`;
  
  // Check cache
  const cached = await this.fastify.redis.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);
  }
  
  // Fetch from database
  const notifications = await this.fetchFromDb(userId, filters);
  
  // Cache for 5 minutes
  await this.fastify.redis.setex(cacheKey, 300, JSON.stringify(notifications));
  
  return notifications;
}
```

### Add Indexes
```sql
-- Performance indexes
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = false;
```

## Step 11: Security Considerations

### Input Validation
```typescript
// Strict input validation
const CreateNotificationSchema = z.object({
  userId: z.string().uuid(),
  type: z.enum(['info', 'warning', 'error', 'success']),
  title: z.string().min(1).max(255).regex(/^[\w\s\-]+$/),
  message: z.string().min(1).max(1000),
  metadata: z.record(z.any()).optional()
}).strict();
```

### Rate Limiting
```typescript
// Apply rate limiting to endpoints
fastify.get('/', {
  onRequest: [fastify.authenticate],
  preHandler: fastify.rateLimit({
    max: 100,
    timeWindow: '1 minute'
  })
}, handler);
```

## Step 12: Monitoring and Logging

### Add Metrics
```typescript
// Track feature usage
fastify.metrics.increment('notifications.created', { type: notification.type });
fastify.metrics.histogram('notifications.query.duration', duration);
```

### Structured Logging
```typescript
fastify.log.info({
  event: 'notification.created',
  userId: notification.userId,
  type: notification.type,
  notificationId: notification.id
}, 'Notification created successfully');
```

## Final Checklist

```markdown
## Feature Implementation Checklist

### Planning
- [ ] Feature specification documented
- [ ] User stories defined
- [ ] Acceptance criteria clear

### Implementation
- [ ] Database schema created
- [ ] Models implemented with validation
- [ ] Service layer complete
- [ ] Routes implemented
- [ ] Authentication/authorization added

### Testing
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests complete
- [ ] E2E tests for critical paths
- [ ] Performance tests if needed

### Documentation
- [ ] API documentation updated
- [ ] Code comments added
- [ ] README updated if needed
- [ ] Migration guide if breaking changes

### Security
- [ ] Input validation strict
- [ ] SQL injection prevented
- [ ] Rate limiting applied
- [ ] Permissions verified

### Performance
- [ ] Database indexes added
- [ ] Caching implemented where needed
- [ ] N+1 queries prevented
- [ ] Response times acceptable

### Monitoring
- [ ] Logging added
- [ ] Metrics tracked
- [ ] Alerts configured
- [ ] Error handling comprehensive
```