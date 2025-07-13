# Fastify Backend Project Knowledge

## Project Overview

This is a Node.js backend application built with Fastify, a fast and low-overhead web framework for Node.js. The project follows modern backend development practices with a focus on performance, type safety, and maintainability.

## Technology Stack

- **Framework**: Fastify v4+
- **Language**: TypeScript/JavaScript
- **Database**: PostgreSQL with TypeORM or Prisma
- **Testing**: Jest with Fastify testing utilities
- **Validation**: Ajv (built into Fastify)
- **Authentication**: JWT with @fastify/jwt
- **Documentation**: Swagger with @fastify/swagger

## Architecture Patterns

- **Plugin-based architecture**: Fastify's core principle
- **Dependency injection**: Using Fastify's decorators
- **Schema-first approach**: All routes have JSON schemas
- **Modular routing**: Routes organized by domain/feature
- **Middleware as plugins**: Custom logic as reusable plugins

## Code Organization

```
src/
├── app.ts                 # Main application setup
├── server.ts             # Server startup
├── routes/               # Route definitions
│   ├── users.ts
│   ├── auth.ts
│   └── health.ts
├── plugins/              # Custom plugins
│   ├── database.ts
│   ├── auth.ts
│   └── swagger.ts
├── schemas/              # JSON schemas
│   ├── user.json
│   └── auth.json
├── services/             # Business logic
│   ├── UserService.ts
│   └── AuthService.ts
├── models/               # Data models
└── utils/                # Utility functions
```

## Development Guidelines

### Route Definition

- Always define JSON schemas for request/response validation
- Use async/await for asynchronous operations
- Implement proper error handling
- Keep route handlers thin, delegate to services

### Plugin Development

- Use `fastify-plugin` wrapper for encapsulation
- Implement proper lifecycle hooks
- Use decorators for adding functionality
- Follow the plugin dependency model

### Database Integration

- Use connection pooling for performance
- Implement proper transaction handling
- Use TypeORM or Prisma for ORM capabilities
- Handle database errors gracefully

### Authentication & Authorization

- Implement JWT-based authentication
- Use guards/hooks for route protection
- Validate user permissions per endpoint
- Implement refresh token mechanism

### Testing Strategy

- Unit tests for services and utilities
- Integration tests for routes using `fastify.inject()`
- Mock external dependencies
- Test error scenarios and edge cases

### Performance Optimization

- Use Fastify's built-in serialization
- Implement caching strategies
- Use appropriate HTTP status codes
- Monitor performance metrics

## Common Patterns

### Service Layer Pattern

```typescript
// services/UserService.ts
export class UserService {
  constructor(private db: Database) {}

  async createUser(userData: CreateUserDto): Promise<User> {
    // Business logic here
  }

  async getUserById(id: string): Promise<User | null> {
    // Database query logic
  }
}
```

### Plugin Pattern

```typescript
// plugins/database.ts
import fp from 'fastify-plugin';

async function databasePlugin(fastify: FastifyInstance) {
  const client = new DatabaseClient(process.env.DATABASE_URL);

  fastify.decorate('db', client);

  fastify.addHook('onClose', async () => {
    await client.close();
  });
}

export default fp(databasePlugin);
```

### Schema-First Route Pattern

```typescript
// routes/users.ts
const createUserSchema = {
  body: {
    type: 'object',
    required: ['email', 'name'],
    properties: {
      email: { type: 'string', format: 'email' },
      name: { type: 'string', minLength: 1 },
    },
  },
};

export default async function userRoutes(fastify: FastifyInstance) {
  fastify.post(
    '/users',
    { schema: createUserSchema },
    async (request, reply) => {
      const user = await fastify.userService.createUser(request.body);
      return { user };
    }
  );
}
```

## Key Dependencies

- `fastify` - Core framework
- `@fastify/swagger` - API documentation
- `@fastify/jwt` - JWT authentication
- `@fastify/cors` - CORS handling
- `@fastify/helmet` - Security headers
- `@fastify/rate-limit` - Rate limiting
- `@fastify/autoload` - Automatic plugin loading
- `fastify-plugin` - Plugin wrapper utility

## Environment Configuration

```
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
JWT_SECRET=your-jwt-secret
LOG_LEVEL=info
```

## Error Handling Approach

- Use Fastify's built-in error handling
- Create custom error classes for business logic
- Implement global error handler
- Log errors with appropriate context
- Return consistent error responses

## Security Considerations

- Input validation using JSON schemas
- Authentication using JWT tokens
- Rate limiting to prevent abuse
- CORS configuration for cross-origin requests
- Security headers using Helmet
- SQL injection prevention with parameterized queries

## Performance Monitoring

- Use Fastify's built-in metrics
- Monitor response times and throughput
- Track database query performance
- Implement health check endpoints
- Use APM tools for production monitoring

## Deployment Notes

- Use PM2 for process management
- Configure proper logging
- Set up health checks
- Use environment variables for configuration
- Implement graceful shutdown handling
