# Performance Optimization Guide - Backend (Fastify)

This command helps you identify and fix performance bottlenecks in your backend application.

## Step 1: Performance Baseline

### Setup Performance Monitoring
```bash
# Install performance monitoring tools
npm install --save-dev clinic autocannon

# Install APM agents (choose one)
npm install --save @sentry/node
npm install --save newrelic
npm install --save @appdynamics/appdynamics
```

### Establish Baseline Metrics
```bash
# Run load test to establish baseline
npx autocannon -c 100 -d 30 http://localhost:3000/api/health

# Save baseline results
npx autocannon -c 100 -d 30 --json http://localhost:3000/api/users > baseline-$(date +%Y%m%d).json
```

### Key Metrics to Track
- **Response Time**: p50, p95, p99
- **Throughput**: Requests per second
- **Error Rate**: Failed requests percentage
- **CPU Usage**: Average and peak
- **Memory Usage**: Heap size and usage
- **Database**: Query time and connection pool

## Step 2: Performance Profiling

### CPU Profiling
```bash
# Using clinic.js
npx clinic doctor -- node dist/server.js

# Generate flame graph
npx clinic flame -- node dist/server.js

# Using native V8 profiler
node --prof dist/server.js
# Process the log
node --prof-process isolate-*.log > profile.txt
```

### Memory Profiling
```bash
# Memory usage analysis
npx clinic heapprofiler -- node dist/server.js

# Detect memory leaks
node --expose-gc --inspect dist/server.js
# Use Chrome DevTools Memory Profiler
```

### Event Loop Monitoring
```typescript
// Add event loop lag monitoring
import { monitorEventLoopDelay } from 'perf_hooks';

const histogram = monitorEventLoopDelay({ resolution: 10 });
histogram.enable();

setInterval(() => {
  console.log(`Event loop delay: ${histogram.mean / 1e6}ms`);
  console.log(`Max delay: ${histogram.max / 1e6}ms`);
}, 5000);
```

## Step 3: Database Optimization

### Query Performance Analysis
```typescript
// Enable query logging with timing
const db = knex({
  client: 'pg',
  debug: true, // Development only
  pool: {
    afterCreate: (conn, done) => {
      conn.query('SET statement_timeout = 5000', (err) => {
        done(err, conn);
      });
    }
  }
});

// Add query timing
db.on('query', (query) => {
  console.time(`Query ${query.__knexQueryUid}`);
});

db.on('query-response', (response, query) => {
  console.timeEnd(`Query ${query.__knexQueryUid}`);
});
```

### Optimize Slow Queries
```sql
-- Find slow queries in PostgreSQL
SELECT 
  query,
  calls,
  total_time,
  mean_time,
  max_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY idx_orders_user_created ON orders(user_id, created_at);
```

### Connection Pool Optimization
```typescript
const db = knex({
  client: 'pg',
  connection: process.env.DATABASE_URL,
  pool: {
    min: 2,
    max: 10,
    acquireTimeoutMillis: 30000,
    createTimeoutMillis: 30000,
    destroyTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
    reapIntervalMillis: 1000,
    createRetryIntervalMillis: 100
  }
});

// Monitor pool usage
setInterval(() => {
  const pool = db.client.pool;
  console.log({
    used: pool.numUsed(),
    free: pool.numFree(),
    pending: pool.numPendingCreates(),
    queued: pool.numPendingAcquires()
  });
}, 10000);
```

## Step 4: Caching Implementation

### In-Memory Caching
```typescript
import NodeCache from 'node-cache';

const cache = new NodeCache({ 
  stdTTL: 600, // 10 minutes default
  checkperiod: 120 // Check for expired keys every 2 minutes
});

// Cache decorator
function Cacheable(ttl: number = 600) {
  return function (target: any, propertyName: string, descriptor: PropertyDescriptor) {
    const method = descriptor.value;
    
    descriptor.value = async function (...args: any[]) {
      const key = `${propertyName}:${JSON.stringify(args)}`;
      const cached = cache.get(key);
      
      if (cached) {
        return cached;
      }
      
      const result = await method.apply(this, args);
      cache.set(key, result, ttl);
      return result;
    };
  };
}

// Usage
class UserService {
  @Cacheable(300)
  async getUser(id: string) {
    return await db('users').where({ id }).first();
  }
}
```

### Redis Caching
```typescript
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
  maxRetriesPerRequest: 3
});

// Caching middleware
async function cacheMiddleware(req: FastifyRequest, reply: FastifyReply) {
  const key = `cache:${req.method}:${req.url}`;
  
  const cached = await redis.get(key);
  if (cached) {
    reply.header('X-Cache', 'HIT');
    return reply.send(JSON.parse(cached));
  }
  
  reply.header('X-Cache', 'MISS');
}

// Cache response
app.addHook('onSend', async (request, reply, payload) => {
  if (reply.statusCode === 200 && request.method === 'GET') {
    const key = `cache:${request.method}:${request.url}`;
    await redis.setex(key, 300, JSON.stringify(payload));
  }
  return payload;
});
```

## Step 5: API Response Optimization

### Pagination Implementation
```typescript
interface PaginationParams {
  page: number;
  limit: number;
  sort?: string;
  order?: 'asc' | 'desc';
}

async function paginatedQuery(
  query: Knex.QueryBuilder,
  params: PaginationParams
) {
  const { page = 1, limit = 20, sort = 'id', order = 'asc' } = params;
  const offset = (page - 1) * limit;
  
  // Get total count (optimized with separate query)
  const [{ count }] = await query.clone().count('* as count');
  
  // Get paginated results
  const results = await query
    .orderBy(sort, order)
    .limit(limit)
    .offset(offset);
  
  return {
    data: results,
    pagination: {
      total: parseInt(count),
      page,
      limit,
      pages: Math.ceil(count / limit)
    }
  };
}
```

### Response Compression
```typescript
import compress from '@fastify/compress';

app.register(compress, {
  global: true,
  threshold: 1024, // Only compress responses larger than 1KB
  encodings: ['gzip', 'deflate', 'br']
});
```

### Field Selection (Sparse Fieldsets)
```typescript
// Allow clients to select fields
app.get('/api/users/:id', async (request, reply) => {
  const fields = request.query.fields?.split(',') || ['*'];
  
  const user = await db('users')
    .select(fields)
    .where({ id: request.params.id })
    .first();
  
  return user;
});
```

## Step 6: Asynchronous Processing

### Job Queue Implementation
```typescript
import Queue from 'bull';

const emailQueue = new Queue('email', {
  redis: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
  }
});

// Process jobs
emailQueue.process(async (job) => {
  const { to, subject, body } = job.data;
  await sendEmail(to, subject, body);
});

// Add job to queue instead of blocking
app.post('/api/notifications', async (request, reply) => {
  const notification = await createNotification(request.body);
  
  // Queue email sending
  await emailQueue.add('send-notification-email', {
    to: notification.userEmail,
    subject: notification.title,
    body: notification.message
  });
  
  // Return immediately
  reply.code(201).send({ data: notification });
});
```

### Stream Processing
```typescript
// Stream large datasets
app.get('/api/export/users', async (request, reply) => {
  reply.type('application/json');
  reply.raw.write('[');
  
  let first = true;
  const stream = db('users').stream();
  
  stream.on('data', (user) => {
    if (!first) reply.raw.write(',');
    first = false;
    reply.raw.write(JSON.stringify(user));
  });
  
  stream.on('end', () => {
    reply.raw.write(']');
    reply.raw.end();
  });
  
  stream.on('error', (err) => {
    reply.code(500).send({ error: err.message });
  });
});
```

## Step 7: Fastify-Specific Optimizations

### Schema Compilation
```typescript
// Pre-compile schemas for better performance
const userSchema = {
  type: 'object',
  properties: {
    id: { type: 'string' },
    name: { type: 'string' },
    email: { type: 'string', format: 'email' }
  }
};

// Fastify will compile this once
app.get('/api/users/:id', {
  schema: {
    response: {
      200: userSchema
    }
  }
}, handler);
```

### Use Fastify Plugins Efficiently
```typescript
// Register plugins correctly
app.register(async function (fastify) {
  // Plugin-scoped decorators and hooks
  fastify.decorate('utility', utilityFunction);
  
  // Routes using this utility
  fastify.get('/route1', handler1);
  fastify.get('/route2', handler2);
});
```

### Optimize Logging
```typescript
// Use appropriate log levels
const logger = {
  development: {
    transport: {
      target: 'pino-pretty',
      options: {
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname'
      }
    }
  },
  production: true, // Use default pino for production
  test: false
};

app = fastify({ logger: logger[process.env.NODE_ENV] });
```

## Step 8: Infrastructure Optimization

### Clustering
```typescript
import cluster from 'cluster';
import os from 'os';

if (cluster.isPrimary) {
  const numCPUs = os.cpus().length;
  
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }
  
  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died`);
    cluster.fork(); // Replace dead workers
  });
} else {
  // Worker process - start server
  startServer();
}
```

### HTTP/2 Support
```typescript
import fs from 'fs';

const app = fastify({
  http2: true,
  https: {
    allowHTTP1: true, // Fallback support
    key: fs.readFileSync('path/to/key.pem'),
    cert: fs.readFileSync('path/to/cert.pem')
  }
});
```

## Step 9: Monitoring and Alerting

### Custom Metrics
```typescript
import { register, Counter, Histogram } from 'prom-client';

const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status']
});

const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

app.addHook('onRequest', async (request, reply) => {
  request.startTime = Date.now();
});

app.addHook('onResponse', async (request, reply) => {
  const duration = (Date.now() - request.startTime) / 1000;
  const labels = {
    method: request.method,
    route: request.routerPath || request.url,
    status: reply.statusCode
  };
  
  httpRequestDuration.observe(labels, duration);
  httpRequestTotal.inc(labels);
});

// Metrics endpoint
app.get('/metrics', async (request, reply) => {
  reply.type('text/plain');
  return register.metrics();
});
```

## Step 10: Performance Testing

### Load Testing Scripts
```bash
# Create load test scenarios
cat > load-test.yml << EOF
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Ramp up"
    - duration: 300
      arrivalRate: 100
      name: "Sustained load"
scenarios:
  - name: "User Flow"
    flow:
      - post:
          url: "/api/auth/login"
          json:
            email: "test@example.com"
            password: "password"
          capture:
            json: "$.token"
            as: "token"
      - get:
          url: "/api/users/profile"
          headers:
            Authorization: "Bearer {{ token }}"
EOF

# Run load test
npx artillery run load-test.yml
```

### Performance Report
```bash
# Generate performance report
mkdir -p reports/performance/$(date +%Y%m%d)

# Run comprehensive performance test
npm run build
npx clinic doctor -- node dist/server.js &
SERVER_PID=$!
sleep 5

# Run load test
npx autocannon -c 200 -d 60 --json http://localhost:3000/api/users > reports/performance/$(date +%Y%m%d)/load-test.json

# Stop server
kill $SERVER_PID

# Generate report
node scripts/generate-performance-report.js
```

## Performance Optimization Checklist

```markdown
## Performance Optimization Checklist

### Database
- [ ] Queries optimized with EXPLAIN
- [ ] Appropriate indexes created
- [ ] Connection pooling configured
- [ ] N+1 queries eliminated
- [ ] Read replicas utilized

### Caching
- [ ] Static content cached
- [ ] Database query results cached
- [ ] Redis/Memcached implemented
- [ ] Cache invalidation strategy
- [ ] CDN configured

### API Design
- [ ] Pagination implemented
- [ ] Response compression enabled
- [ ] Field selection available
- [ ] Batch endpoints created
- [ ] GraphQL for flexible queries

### Code Optimization
- [ ] Async/await used properly
- [ ] Memory leaks fixed
- [ ] Large objects streamed
- [ ] CPU-intensive tasks queued
- [ ] Dependencies minimized

### Infrastructure
- [ ] Horizontal scaling ready
- [ ] Load balancer configured
- [ ] Auto-scaling policies
- [ ] Resource limits set
- [ ] Monitoring alerts configured
```