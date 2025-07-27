# Deployment Guide - Backend (Fastify)

This command guides you through deploying your backend application to various environments.

## Step 1: Pre-Deployment Checklist

### Code Quality Checks
```bash
# Run all quality checks
npm run lint
npm run type-check
npm test
npm run test:integration
npm audit

# Build the application
npm run build

# Test the production build
NODE_ENV=production node dist/server.js
```

### Environment Configuration
```bash
# Verify environment variables
node scripts/verify-env.js

# Create production .env file
cat > .env.production << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://user:pass@prod-db:5432/app
REDIS_URL=redis://prod-redis:6379
JWT_SECRET=$(openssl rand -base64 32)
SENTRY_DSN=your-sentry-dsn
LOG_LEVEL=info
EOF
```

### Database Preparation
```bash
# Run pending migrations
NODE_ENV=production npm run migrate:latest

# Verify database state
NODE_ENV=production npm run migrate:status

# Create database backup
pg_dump $DATABASE_URL > backup-$(date +%Y%m%d-%H%M%S).sql
```

## Step 2: Docker Deployment

### Multi-Stage Dockerfile
```dockerfile
# Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci --only=production
RUN npm ci --only=development

# Copy source code
COPY src ./src

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs package*.json ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Use dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/server.js"]
```

### Build and Push Docker Image
```bash
# Build image
docker build -t myapp/backend:$(git rev-parse --short HEAD) .
docker tag myapp/backend:$(git rev-parse --short HEAD) myapp/backend:latest

# Test locally
docker run -p 3000:3000 --env-file .env.production myapp/backend:latest

# Push to registry
docker push myapp/backend:$(git rev-parse --short HEAD)
docker push myapp/backend:latest
```

## Step 3: Kubernetes Deployment

### Kubernetes Manifests
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: api
        image: myapp/backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: backend-secrets
              key: database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

### Deploy to Kubernetes
```bash
# Create namespace
kubectl create namespace production

# Create secrets
kubectl create secret generic backend-secrets \
  --from-env-file=.env.production \
  -n production

# Apply manifests
kubectl apply -f k8s/ -n production

# Check deployment status
kubectl rollout status deployment/backend-api -n production

# Get service endpoint
kubectl get service backend-service -n production
```

## Step 4: AWS Deployment

### ECS with Fargate
```json
// task-definition.json
{
  "family": "backend-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "api",
      "image": "myapp/backend:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:db-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/backend-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### Deploy to ECS
```bash
# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create service
aws ecs create-service \
  --cluster production \
  --service-name backend-api \
  --task-definition backend-api:1 \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"

# Update service with new version
aws ecs update-service \
  --cluster production \
  --service backend-api \
  --task-definition backend-api:2
```

### Elastic Beanstalk
```bash
# Initialize EB
eb init -p node.js-18 backend-api

# Create environment
eb create production --instance-type t3.small

# Deploy
eb deploy

# Open in browser
eb open
```

## Step 5: Heroku Deployment

### Heroku Configuration
```json
// package.json
{
  "engines": {
    "node": "18.x",
    "npm": "8.x"
  },
  "scripts": {
    "heroku-postbuild": "npm run build",
    "start": "node dist/server.js"
  }
}
```

### Deploy to Heroku
```bash
# Create app
heroku create backend-api-prod

# Add PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# Add Redis
heroku addons:create heroku-redis:hobby-dev

# Set environment variables
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=$(openssl rand -base64 32)

# Deploy
git push heroku main

# Run migrations
heroku run npm run migrate:latest

# Check logs
heroku logs --tail
```

## Step 6: CI/CD Pipeline

### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: 18
    - run: npm ci
    - run: npm test
    - run: npm run build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: |
        docker build -t ${{ secrets.DOCKER_REGISTRY }}/backend:${{ github.sha }} .
        docker tag ${{ secrets.DOCKER_REGISTRY }}/backend:${{ github.sha }} ${{ secrets.DOCKER_REGISTRY }}/backend:latest
    
    - name: Push to registry
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push ${{ secrets.DOCKER_REGISTRY }}/backend:${{ github.sha }}
        docker push ${{ secrets.DOCKER_REGISTRY }}/backend:latest
    
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/backend-api api=${{ secrets.DOCKER_REGISTRY }}/backend:${{ github.sha }} -n production
        kubectl rollout status deployment/backend-api -n production
```

### GitLab CI/CD
```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  image: node:18
  script:
    - npm ci
    - npm test
    - npm run build

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/backend-api api=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -n production
    - kubectl rollout status deployment/backend-api -n production
  only:
    - main
```

## Step 7: Zero-Downtime Deployment

### Blue-Green Deployment
```bash
# Deploy to green environment
kubectl apply -f k8s/deployment-green.yaml

# Wait for green to be ready
kubectl wait --for=condition=available --timeout=300s deployment/backend-api-green

# Switch traffic to green
kubectl patch service backend-service -p '{"spec":{"selector":{"version":"green"}}}'

# Remove blue deployment
kubectl delete deployment backend-api-blue
```

### Rolling Update Strategy
```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

## Step 8: Post-Deployment Tasks

### Health Checks
```bash
# Verify deployment health
curl https://api.example.com/health

# Check all instances
for i in {1..3}; do
  kubectl exec backend-api-$i -- curl localhost:3000/health
done
```

### Smoke Tests
```bash
# Run smoke tests
npm run test:smoke -- --url=https://api.example.com

# Basic API tests
curl -X POST https://api.example.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test"}'
```

### Monitor Deployment
```bash
# Watch logs
kubectl logs -f deployment/backend-api -n production

# Monitor metrics
kubectl top pods -n production

# Check error rates
curl https://api.example.com/metrics | grep http_requests_total
```

## Step 9: Rollback Procedures

### Kubernetes Rollback
```bash
# View rollout history
kubectl rollout history deployment/backend-api

# Rollback to previous version
kubectl rollout undo deployment/backend-api

# Rollback to specific revision
kubectl rollout undo deployment/backend-api --to-revision=2
```

### Database Rollback
```bash
# Rollback last migration
npm run migrate:rollback

# Restore from backup
psql $DATABASE_URL < backup-20231225-120000.sql
```

## Step 10: Production Monitoring Setup

### Configure Monitoring
```typescript
// src/monitoring.ts
import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  integrations: [
    new ProfilingIntegration(),
  ],
  tracesSampleRate: 0.1,
  profilesSampleRate: 0.1,
  environment: process.env.NODE_ENV
});

// APM Integration
import newrelic from 'newrelic';

// Custom metrics
app.addHook('onResponse', async (request, reply) => {
  newrelic.recordMetric('Custom/API/ResponseTime', reply.getResponseTime());
  newrelic.recordMetric(`Custom/API/Status/${reply.statusCode}`, 1);
});
```

### Setup Alerts
```yaml
# k8s/monitoring/alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backend-alerts
spec:
  groups:
  - name: backend
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      annotations:
        summary: "High error rate detected"
    - alert: HighResponseTime
      expr: histogram_quantile(0.95, http_request_duration_seconds) > 1
      for: 5m
      annotations:
        summary: "High response time detected"
```

## Deployment Checklist

```markdown
## Production Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Security audit completed
- [ ] Performance benchmarks acceptable
- [ ] Database migrations ready
- [ ] Environment variables configured
- [ ] Backup created

### Deployment
- [ ] Docker image built and pushed
- [ ] Deployment manifest updated
- [ ] Health checks passing
- [ ] Smoke tests successful
- [ ] Monitoring configured
- [ ] Logs accessible

### Post-Deployment
- [ ] Error rates normal
- [ ] Response times acceptable
- [ ] All features working
- [ ] Database queries performing well
- [ ] No memory leaks detected
- [ ] Customers notified (if needed)

### Rollback Ready
- [ ] Previous version tagged
- [ ] Database backup available
- [ ] Rollback procedure documented
- [ ] Team aware of rollback steps
```