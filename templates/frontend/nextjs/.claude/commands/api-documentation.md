# API Documentation Guide - Frontend (Next.js)

This command helps you create and maintain comprehensive API documentation.

## Step 1: OpenAPI/Swagger Setup

### Install Dependencies
```bash
# Install Swagger dependencies
npm install --save @fastify/swagger @fastify/swagger-ui

# Install documentation tools
npm install --save-dev @apidevtools/swagger-cli spectacle-docs
```

### Configure Swagger
```typescript
// src/plugins/swagger.ts
import fp from 'fastify-plugin';
import swagger from '@fastify/swagger';
import swaggerUI from '@fastify/swagger-ui';

export default fp(async (fastify) => {
  await fastify.register(swagger, {
    openapi: {
      openapi: '3.0.0',
      info: {
        title: 'Backend API',
        description: 'Comprehensive API documentation for our backend services',
        version: '1.0.0',
        contact: {
          name: 'API Support',
          email: 'api@example.com',
          url: 'https://support.example.com'
        },
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT'
        }
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://api-staging.example.com',
          description: 'Staging server'
        },
        {
          url: 'https://api.example.com',
          description: 'Production server'
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT'
          },
          apiKey: {
            type: 'apiKey',
            in: 'header',
            name: 'X-API-Key'
          }
        }
      },
      tags: [
        { name: 'Auth', description: 'Authentication endpoints' },
        { name: 'Users', description: 'User management' },
        { name: 'Admin', description: 'Admin operations' }
      ]
    }
  });

  await fastify.register(swaggerUI, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: true,
      displayRequestDuration: true
    },
    staticCSP: true,
    transformStaticCSP: (header) => header,
    transformSpecification: (swaggerObject, request, reply) => {
      return swaggerObject;
    }
  });
});
```

## Step 2: Document Endpoints

### Schema Documentation
```typescript
// Define reusable schemas
export const UserSchema = {
  type: 'object',
  properties: {
    id: { type: 'string', format: 'uuid', description: 'Unique user identifier' },
    email: { type: 'string', format: 'email', description: 'User email address' },
    name: { type: 'string', minLength: 1, maxLength: 100, description: 'User full name' },
    role: { type: 'string', enum: ['user', 'admin'], description: 'User role' },
    createdAt: { type: 'string', format: 'date-time', description: 'Account creation timestamp' },
    updatedAt: { type: 'string', format: 'date-time', description: 'Last update timestamp' }
  },
  required: ['id', 'email', 'name', 'role'],
  additionalProperties: false
};

export const ErrorSchema = {
  type: 'object',
  properties: {
    statusCode: { type: 'number', description: 'HTTP status code' },
    error: { type: 'string', description: 'Error type' },
    message: { type: 'string', description: 'Error message' },
    validation: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          field: { type: 'string' },
          message: { type: 'string' }
        }
      }
    }
  },
  required: ['statusCode', 'error', 'message']
};
```

### Route Documentation
```typescript
// Comprehensive route documentation
app.post('/api/auth/login', {
  schema: {
    description: 'Authenticate user and receive access token',
    tags: ['Auth'],
    summary: 'User login',
    body: {
      type: 'object',
      required: ['email', 'password'],
      properties: {
        email: { 
          type: 'string', 
          format: 'email',
          description: 'User email address',
          example: 'user@example.com'
        },
        password: { 
          type: 'string', 
          minLength: 8,
          description: 'User password',
          example: 'SecurePass123!'
        }
      }
    },
    response: {
      200: {
        description: 'Successful authentication',
        type: 'object',
        properties: {
          token: { 
            type: 'string',
            description: 'JWT access token',
            example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
          },
          refreshToken: {
            type: 'string',
            description: 'Refresh token for token renewal',
            example: 'f47ac10b-58cc-4372-a567-0e02b2c3d479'
          },
          user: {
            ...UserSchema,
            description: 'Authenticated user information'
          }
        }
      },
      400: {
        description: 'Invalid request data',
        ...ErrorSchema
      },
      401: {
        description: 'Invalid credentials',
        ...ErrorSchema
      },
      429: {
        description: 'Too many login attempts',
        ...ErrorSchema,
        headers: {
          'Retry-After': {
            type: 'integer',
            description: 'Seconds until next attempt allowed'
          }
        }
      }
    }
  }
}, loginHandler);
```

### Complex Endpoint Documentation
```typescript
app.get('/api/users', {
  schema: {
    description: 'Get paginated list of users with filtering and sorting',
    tags: ['Users'],
    summary: 'List users',
    security: [{ bearerAuth: [] }],
    querystring: {
      type: 'object',
      properties: {
        page: { 
          type: 'integer', 
          minimum: 1, 
          default: 1,
          description: 'Page number' 
        },
        limit: { 
          type: 'integer', 
          minimum: 1, 
          maximum: 100, 
          default: 20,
          description: 'Items per page' 
        },
        search: { 
          type: 'string',
          description: 'Search by name or email' 
        },
        role: { 
          type: 'string',
          enum: ['user', 'admin'],
          description: 'Filter by role' 
        },
        sortBy: { 
          type: 'string',
          enum: ['name', 'email', 'createdAt'],
          default: 'createdAt',
          description: 'Field to sort by' 
        },
        sortOrder: { 
          type: 'string',
          enum: ['asc', 'desc'],
          default: 'desc',
          description: 'Sort direction' 
        }
      }
    },
    response: {
      200: {
        description: 'Paginated user list',
        type: 'object',
        properties: {
          data: {
            type: 'array',
            items: UserSchema
          },
          pagination: {
            type: 'object',
            properties: {
              page: { type: 'integer' },
              limit: { type: 'integer' },
              total: { type: 'integer' },
              pages: { type: 'integer' }
            }
          }
        }
      }
    }
  }
}, getUsersHandler);
```

## Step 3: Generate API Documentation

### Export OpenAPI Specification
```bash
# Generate OpenAPI spec
node -e "
const app = require('./dist/app').build();
app.ready().then(() => {
  const spec = app.swagger();
  require('fs').writeFileSync('openapi.json', JSON.stringify(spec, null, 2));
  console.log('OpenAPI spec generated');
  process.exit(0);
});
"

# Validate specification
npx @apidevtools/swagger-cli validate openapi.json

# Bundle multi-file specs
npx @apidevtools/swagger-cli bundle openapi.yaml -o openapi-bundled.json
```

### Generate Documentation Formats
```bash
# Generate HTML documentation
npx spectacle -d ./docs/api openapi.json

# Generate Markdown
npx widdershins openapi.json -o docs/API.md

# Generate Postman collection
npx openapi-to-postmanv2 -s openapi.json -o postman-collection.json
```

## Step 4: API Versioning Documentation

### Version Management
```typescript
// API versioning strategy
app.register(v1Routes, { prefix: '/api/v1' });
app.register(v2Routes, { prefix: '/api/v2' });

// Document version differences
const versionDoc = {
  'v1': {
    deprecated: false,
    sunsetDate: null,
    changes: []
  },
  'v2': {
    deprecated: false,
    sunsetDate: null,
    changes: [
      'Added pagination to all list endpoints',
      'Changed user.fullName to user.name',
      'Removed legacy authentication endpoint'
    ]
  }
};
```

### Migration Guide
```markdown
# API Version Migration Guide

## Migrating from v1 to v2

### Breaking Changes

1. **User Object Structure**
   - v1: `{ fullName: "John Doe" }`
   - v2: `{ name: "John Doe" }`

2. **Pagination**
   - v1: Returns all results
   - v2: Returns paginated results with metadata

### Deprecated Endpoints
- `POST /api/v1/auth/login-legacy` → Use `POST /api/v2/auth/login`

### New Features in v2
- Webhook support
- Batch operations
- GraphQL endpoint
```

## Step 5: Interactive Documentation

### API Playground
```typescript
// Add try-it-out functionality
app.get('/playground', (request, reply) => {
  reply.type('text/html').send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>API Playground</title>
      <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist/swagger-ui.css">
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js"></script>
      <script>
        SwaggerUIBundle({
          url: '/docs/json',
          dom_id: '#swagger-ui',
          presets: [
            SwaggerUIBundle.presets.apis,
            SwaggerUIBundle.SwaggerUIStandalonePreset
          ],
          layout: "BaseLayout",
          tryItOutEnabled: true,
          requestInterceptor: (req) => {
            // Add auth token from localStorage
            const token = localStorage.getItem('api_token');
            if (token) {
              req.headers['Authorization'] = 'Bearer ' + token;
            }
            return req;
          }
        });
      </script>
    </body>
    </html>
  `);
});
```

### Code Examples
```typescript
// Generate code examples for each endpoint
const codeExamples = {
  curl: (endpoint) => `curl -X ${endpoint.method} \\
  ${endpoint.url} \\
  -H "Authorization: Bearer YOUR_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '${JSON.stringify(endpoint.body, null, 2)}'`,
  
  javascript: (endpoint) => `fetch('${endpoint.url}', {
  method: '${endpoint.method}',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(${JSON.stringify(endpoint.body, null, 2)})
})
.then(response => response.json())
.then(data => console.log(data));`,

  python: (endpoint) => `import requests

response = requests.${endpoint.method.toLowerCase()}(
    '${endpoint.url}',
    headers={
        'Authorization': 'Bearer YOUR_TOKEN',
        'Content-Type': 'application/json'
    },
    json=${JSON.stringify(endpoint.body, null, 2)}
)

print(response.json())`
};
```

## Step 6: SDK Generation

### Generate Client SDKs
```bash
# Install OpenAPI Generator
npm install -g @openapitools/openapi-generator-cli

# Generate TypeScript SDK
openapi-generator-cli generate \
  -i openapi.json \
  -g typescript-axios \
  -o ./sdk/typescript

# Generate Python SDK
openapi-generator-cli generate \
  -i openapi.json \
  -g python \
  -o ./sdk/python

# Generate Go SDK
openapi-generator-cli generate \
  -i openapi.json \
  -g go \
  -o ./sdk/go
```

### SDK Documentation
```markdown
# SDK Usage

## TypeScript
\`\`\`typescript
import { ApiClient, UsersApi } from '@company/api-sdk';

const client = new ApiClient();
client.accessToken = 'YOUR_TOKEN';

const usersApi = new UsersApi(client);
const users = await usersApi.getUsers({ page: 1, limit: 20 });
\`\`\`

## Python
\`\`\`python
from company_api import ApiClient, UsersApi

client = ApiClient()
client.access_token = 'YOUR_TOKEN'

users_api = UsersApi(client)
users = users_api.get_users(page=1, limit=20)
\`\`\`
```

## Step 7: API Testing Documentation

### Request/Response Examples
```yaml
# examples/auth-login.yaml
request:
  method: POST
  url: /api/auth/login
  headers:
    Content-Type: application/json
  body:
    email: user@example.com
    password: SecurePass123!

response:
  status: 200
  headers:
    Content-Type: application/json
  body:
    token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    user:
      id: 123e4567-e89b-12d3-a456-426614174000
      email: user@example.com
      name: John Doe
```

### Error Response Catalog
```markdown
# Common Error Responses

## 400 Bad Request
Returned when request data is invalid.

\`\`\`json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Invalid request data",
  "validation": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
\`\`\`

## 401 Unauthorized
Returned when authentication fails.

\`\`\`json
{
  "statusCode": 401,
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
\`\`\`

## 429 Too Many Requests
Returned when rate limit is exceeded.

\`\`\`json
{
  "statusCode": 429,
  "error": "Too Many Requests",
  "message": "Rate limit exceeded",
  "retryAfter": 60
}
\`\`\`
```

## Step 8: Webhook Documentation

### Webhook Events
```typescript
// Document webhook payloads
export const WebhookSchemas = {
  'user.created': {
    type: 'object',
    properties: {
      event: { type: 'string', const: 'user.created' },
      timestamp: { type: 'string', format: 'date-time' },
      data: UserSchema
    }
  },
  'order.completed': {
    type: 'object',
    properties: {
      event: { type: 'string', const: 'order.completed' },
      timestamp: { type: 'string', format: 'date-time' },
      data: OrderSchema
    }
  }
};

// Webhook endpoint documentation
app.post('/webhooks/configure', {
  schema: {
    description: 'Configure webhook endpoints',
    tags: ['Webhooks'],
    body: {
      type: 'object',
      properties: {
        url: { type: 'string', format: 'uri' },
        events: { 
          type: 'array',
          items: { 
            type: 'string',
            enum: Object.keys(WebhookSchemas)
          }
        },
        secret: { type: 'string', minLength: 32 }
      }
    }
  }
}, configureWebhookHandler);
```

## Step 9: Documentation Automation

### CI/CD Integration
```yaml
# .github/workflows/docs.yml
name: Update API Documentation

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'openapi.yaml'

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Generate OpenAPI spec
      run: |
        npm ci
        npm run build
        npm run docs:generate
    
    - name: Generate documentation
      run: |
        npm run docs:html
        npm run docs:markdown
        npm run docs:postman
    
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./docs/api
```

### Documentation Tests
```typescript
// Test that all routes are documented
describe('API Documentation', () => {
  it('should have all routes documented', async () => {
    const app = build();
    await app.ready();
    
    const routes = app.printRoutes();
    const spec = app.swagger();
    
    routes.forEach(route => {
      const path = route.path.replace(/:(\w+)/g, '{$1}');
      expect(spec.paths[path]).toBeDefined();
      expect(spec.paths[path][route.method.toLowerCase()]).toBeDefined();
    });
  });
});
```

## Step 10: Documentation Best Practices

### README Template
```markdown
# API Documentation

## Quick Start
1. Get your API key from [Dashboard](https://dashboard.example.com)
2. Make your first request:
   \`\`\`bash
   curl -H "Authorization: Bearer YOUR_TOKEN" https://api.example.com/api/users
   \`\`\`

## Base URL
- Production: `https://api.example.com`
- Staging: `https://api-staging.example.com`

## Authentication
All requests require authentication using Bearer tokens.

## Rate Limiting
- 100 requests per minute for standard tier
- 1000 requests per minute for premium tier

## SDKs
- [TypeScript/JavaScript](./sdk/typescript)
- [Python](./sdk/python)
- [Go](./sdk/go)

## Support
- Email: api@example.com
- Slack: [Join our community](https://slack.example.com)
```

### Changelog
```markdown
# API Changelog

## [2.0.0] - 2024-01-15
### Breaking Changes
- Changed `fullName` to `name` in User object
- Removed `/api/v1/legacy` endpoints

### Added
- Pagination for all list endpoints
- Webhook support
- Batch operations

### Fixed
- Rate limiting header format
- Timezone handling in timestamps

## [1.5.0] - 2023-12-01
### Added
- New filters for user listing
- Export functionality
```

## Documentation Checklist

```markdown
## API Documentation Checklist

### Setup
- [ ] OpenAPI/Swagger configured
- [ ] Interactive documentation available
- [ ] Version strategy documented

### Endpoints
- [ ] All endpoints documented
- [ ] Request/response examples
- [ ] Error responses catalogued
- [ ] Authentication documented

### Schemas
- [ ] All models documented
- [ ] Validation rules clear
- [ ] Required fields marked
- [ ] Examples provided

### Developer Experience
- [ ] Getting started guide
- [ ] Code examples in multiple languages
- [ ] SDKs generated
- [ ] Postman collection available

### Maintenance
- [ ] Automated documentation generation
- [ ] Documentation tests
- [ ] Changelog maintained
- [ ] Version migration guides
```