# Production Debugging Guide - Backend (Fastify)

This command helps you debug issues in production environments safely and effectively.

## Step 1: Initial Assessment

### Check Service Health
```bash
# Basic health check
curl -s https://api.example.com/health | jq .

# Detailed health with dependencies
curl -s https://api.example.com/health/detailed | jq .

# Check specific endpoints
for endpoint in users orders payments; do
  echo "Checking /api/$endpoint:"
  curl -s -o /dev/null -w "%{http_code} - %{time_total}s\n" https://api.example.com/api/$endpoint
done
```

### Quick Diagnostics
```bash
# Get current metrics
curl -s https://api.example.com/metrics | grep -E "(up|http_requests_total|error_rate)"

# Check recent deployments
kubectl rollout history deployment/backend-api -n production

# View running pods
kubectl get pods -n production -l app=backend
```

## Step 2: Log Analysis

### Centralized Logging
```bash
# Tail production logs (Kubernetes)
kubectl logs -f deployment/backend-api -n production --tail=100

# Get logs from all pods
kubectl logs -n production -l app=backend --tail=50

# Search for errors in last hour
kubectl logs deployment/backend-api -n production --since=1h | grep -i error

# Export logs for analysis
kubectl logs deployment/backend-api -n production --since=24h > production-logs-$(date +%Y%m%d).log
```

### Log Aggregation Queries
```javascript
// ElasticSearch/Kibana queries
{
  "query": {
    "bool": {
      "must": [
        { "match": { "level": "error" } },
        { "range": { "@timestamp": { "gte": "now-1h" } } }
      ]
    }
  },
  "aggs": {
    "error_types": {
      "terms": { "field": "error.type" }
    }
  }
}

// CloudWatch Insights
fields @timestamp, level, message, error.stack
| filter level = "error"
| stats count() by error.type
| sort count desc
```

### Common Log Patterns
```bash
# Database connection errors
grep -i "connection refused\|timeout\|ECONNREFUSED" logs.txt

# Memory issues
grep -i "heap\|memory\|OOM" logs.txt

# Rate limiting
grep -i "rate limit\|429\|too many requests" logs.txt

# Authentication failures
grep -i "unauthorized\|401\|invalid token" logs.txt
```

## Step 3: Performance Debugging

### Real-time Monitoring
```bash
# CPU and Memory usage (Kubernetes)
kubectl top pods -n production
kubectl top nodes

# Watch resource usage
watch -n 2 'kubectl top pods -n production | grep backend'

# Database connections
kubectl exec -it backend-api-xxx -n production -- \
  psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity;"
```

### APM Integration
```typescript
// Add debug endpoints (protect these!)
app.get('/debug/health/detailed', {
  preHandler: app.authenticate,
  handler: async (request, reply) => {
    const health = {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      connections: {
        database: await checkDatabaseHealth(),
        redis: await checkRedisHealth(),
        external: await checkExternalServices()
      }
    };
    return health;
  }
});
```

### Performance Profiling in Production
```bash
# Enable profiling temporarily
kubectl set env deployment/backend-api NODE_OPTIONS="--inspect=0.0.0.0:9229" -n production

# Port forward for debugging
kubectl port-forward deployment/backend-api 9229:9229 -n production

# Connect Chrome DevTools to chrome://inspect

# Disable after debugging
kubectl set env deployment/backend-api NODE_OPTIONS- -n production
```

## Step 4: Database Debugging

### Query Performance
```sql
-- Find slow queries (PostgreSQL)
SELECT 
  query,
  mean_exec_time,
  calls,
  total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check current connections
SELECT 
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  state_change,
  query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Kill long-running queries
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start < now() - interval '10 minutes';
```

### Connection Pool Issues
```bash
# Check connection pool stats
kubectl exec -it backend-api-xxx -n production -- node -e "
const db = require('./dist/db');
console.log({
  total: db.client.pool.max,
  used: db.client.pool.numUsed(),
  free: db.client.pool.numFree(),
  waiting: db.client.pool.numPendingAcquires()
});
"
```

## Step 5: Memory Debugging

### Memory Leak Detection
```bash
# Take heap snapshot
kubectl exec -it backend-api-xxx -n production -- \
  kill -USR2 $(pgrep -f "node.*server.js")

# Download heap dump
kubectl cp production/backend-api-xxx:/app/heapdump-*.heapsnapshot ./

# Analyze with Chrome DevTools or clinic.js
```

### Memory Usage Analysis
```javascript
// Add memory monitoring endpoint
app.get('/debug/memory', {
  preHandler: [app.authenticate, app.requireRole('admin')],
  handler: async (request, reply) => {
    const usage = process.memoryUsage();
    return {
      rss: `${Math.round(usage.rss / 1024 / 1024)} MB`,
      heapTotal: `${Math.round(usage.heapTotal / 1024 / 1024)} MB`,
      heapUsed: `${Math.round(usage.heapUsed / 1024 / 1024)} MB`,
      external: `${Math.round(usage.external / 1024 / 1024)} MB`,
      arrayBuffers: `${Math.round(usage.arrayBuffers / 1024 / 1024)} MB`
    };
  }
});
```

## Step 6: Request Tracing

### Distributed Tracing
```typescript
// Implement request tracing
app.addHook('onRequest', async (request, reply) => {
  request.traceId = request.headers['x-trace-id'] || generateTraceId();
  reply.header('x-trace-id', request.traceId);
  
  // Log with trace ID
  request.log = request.log.child({ traceId: request.traceId });
});

// Trace specific request
curl -H "X-Trace-ID: debug-$(date +%s)" https://api.example.com/api/problematic-endpoint
```

### Debug Specific User
```bash
# Enable debug logging for specific user
kubectl exec -it backend-api-xxx -n production -- node -e "
const redis = require('./dist/redis');
redis.set('debug:user:123', '1', 'EX', 3600);
"

# In application code
if (await redis.get(`debug:user:${userId}`)) {
  request.log.level = 'debug';
}
```

## Step 7: Live Debugging Techniques

### Remote Debugging (Use with Caution!)
```bash
# SSH tunnel to production pod
kubectl exec -it backend-api-xxx -n production -- /bin/sh

# Inside pod - check processes
ps aux | grep node
netstat -tulpn
df -h
free -m

# Check environment
env | grep -E "(DATABASE|REDIS|API)" | sed 's/=.*/=***/'
```

### Feature Flag Debugging
```typescript
// Toggle features for debugging
app.post('/debug/feature-flags', {
  preHandler: [app.authenticate, app.requireRole('admin')],
  handler: async (request, reply) => {
    const { feature, enabled, duration = 3600 } = request.body;
    await redis.setex(`feature:${feature}`, duration, enabled ? '1' : '0');
    return { feature, enabled, duration };
  }
});
```

## Step 8: Error Investigation

### Error Tracking
```javascript
// Sentry error investigation
const Sentry = require('@sentry/node');

// Add breadcrumbs for context
Sentry.addBreadcrumb({
  category: 'debug',
  message: 'Investigating production issue',
  level: 'info',
  data: { endpoint: request.url }
});

// Capture additional context
Sentry.configureScope((scope) => {
  scope.setTag('debug_session', true);
  scope.setContext('system', {
    memory: process.memoryUsage(),
    uptime: process.uptime()
  });
});
```

### Common Production Issues

#### 1. Memory Leaks
```javascript
// Detect potential leaks
const heapUsed = [];
setInterval(() => {
  const usage = process.memoryUsage().heapUsed / 1024 / 1024;
  heapUsed.push(usage);
  
  if (heapUsed.length > 60) {
    heapUsed.shift();
    
    // Check if memory is consistently increasing
    const trend = heapUsed.slice(-10).reduce((a, b, i) => a + (b - heapUsed[heapUsed.length - 11 + i]), 0);
    if (trend > 50) { // 50MB increase over 10 minutes
      logger.warn('Potential memory leak detected', { trend, current: usage });
    }
  }
}, 10000);
```

#### 2. Connection Pool Exhaustion
```javascript
// Monitor and alert
setInterval(async () => {
  const poolStats = {
    used: db.client.pool.numUsed(),
    free: db.client.pool.numFree(),
    waiting: db.client.pool.numPendingAcquires()
  };
  
  if (poolStats.waiting > 5) {
    logger.error('Database connection pool exhausted', poolStats);
    // Consider increasing pool size or investigating slow queries
  }
}, 5000);
```

## Step 9: Incident Response

### Create Incident Report
```bash
# Gather system state
mkdir -p incidents/$(date +%Y%m%d-%H%M%S)
cd incidents/$(date +%Y%m%d-%H%M%S)

# Collect diagnostics
kubectl describe pods -n production > pods.txt
kubectl top pods -n production > resources.txt
kubectl logs deployment/backend-api -n production --since=1h > logs.txt
curl -s https://api.example.com/metrics > metrics.txt

# Database state
kubectl exec -it backend-api-xxx -n production -- \
  psql $DATABASE_URL -c "\l+" > databases.txt
```

### Emergency Procedures
```bash
# Scale up if needed
kubectl scale deployment/backend-api --replicas=5 -n production

# Restart pods (rolling)
kubectl rollout restart deployment/backend-api -n production

# Emergency maintenance mode
kubectl set env deployment/backend-api MAINTENANCE_MODE=true -n production
```

## Step 10: Post-Incident Analysis

### Generate Debug Report
```markdown
# Production Debug Report

## Incident Summary
- **Time**: $(date)
- **Duration**: X minutes
- **Impact**: X% of users affected
- **Root Cause**: [Identified cause]

## Timeline
- HH:MM - Issue detected
- HH:MM - Investigation started
- HH:MM - Root cause identified
- HH:MM - Fix deployed
- HH:MM - Service restored

## Findings
1. What went wrong
2. Why it went wrong
3. How it was fixed

## Action Items
- [ ] Implement monitoring for X
- [ ] Add alerting for Y
- [ ] Document procedure Z

## Logs and Evidence
- See attached files
```

## Debug Commands Cheatsheet

```bash
# Quick health check
curl -s https://api.example.com/health | jq .

# Get error count
kubectl logs deployment/backend-api -n production --since=1h | grep -c ERROR

# Check database connections
kubectl exec -it backend-api-xxx -n production -- \
  psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity;"

# Memory usage
kubectl top pods -n production | grep backend

# Recent errors with context
kubectl logs deployment/backend-api -n production --since=10m | grep -B2 -A2 ERROR

# Request rate
curl -s https://api.example.com/metrics | grep http_requests_total

# Restart pod
kubectl delete pod backend-api-xxx -n production

# Enable debug logging (temporary)
kubectl set env deployment/backend-api LOG_LEVEL=debug -n production

# Disable debug logging
kubectl set env deployment/backend-api LOG_LEVEL=info -n production
```