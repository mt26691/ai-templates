# Security Audit Guide - Infrastructure (Kubernetes)

This command provides a comprehensive security audit process for your backend application.

## Step 1: Dependency Security Scan

### NPM Audit
```bash
# Run npm security audit
npm audit

# Generate detailed report
npm audit --json > security-audit-$(date +%Y%m%d).json

# Fix automatically where possible
npm audit fix

# Force fixes (careful - may break)
npm audit fix --force
```

### Additional Security Tools
```bash
# Install security scanning tools
npm install -g snyk @npmcli/arborist

# Snyk security scan
snyk test

# Check for known vulnerabilities
snyk monitor

# OWASP dependency check
npx owasp-dependency-check --project "My Project" --scan ./
```

### Check for Outdated Packages
```bash
# List outdated packages
npm outdated

# Update dependencies safely
npx npm-check-updates -u --target minor
npm install
npm test
```

## Step 2: Code Security Analysis

### Static Application Security Testing (SAST)
```bash
# Install security linters
npm install --save-dev eslint-plugin-security

# Run security-focused ESLint
npx eslint --ext .ts,.js src/ --plugin security

# Use semgrep for pattern matching
docker run --rm -v "${PWD}:/src" returntocorp/semgrep --config=auto
```

### Common Security Vulnerabilities to Check

#### 1. SQL Injection
```typescript
// ❌ Vulnerable
const user = await db.raw(`SELECT * FROM users WHERE id = ${userId}`);

// ✅ Safe
const user = await db('users').where('id', userId).first();
// or
const user = await db.raw('SELECT * FROM users WHERE id = ?', [userId]);
```

#### 2. NoSQL Injection
```typescript
// ❌ Vulnerable
const user = await collection.findOne({ username: req.body.username });

// ✅ Safe
const user = await collection.findOne({ 
  username: { $eq: sanitize(req.body.username) } 
});
```

#### 3. XSS Prevention
```typescript
// ❌ Vulnerable
reply.type('text/html').send(`<h1>Hello ${username}</h1>`);

// ✅ Safe
import { escape } from 'html-escaper';
reply.type('text/html').send(`<h1>Hello ${escape(username)}</h1>`);
```

## Step 3: Authentication & Authorization Audit

### JWT Security Check
```typescript
// Check JWT implementation
// ❌ Weak configuration
const token = jwt.sign(payload, 'secret');

// ✅ Secure configuration
const token = jwt.sign(payload, process.env.JWT_SECRET, {
  expiresIn: '1h',
  algorithm: 'RS256',
  issuer: 'your-app',
  audience: 'your-app-users'
});
```

### Password Security
```typescript
// ❌ Weak hashing
const hash = crypto.createHash('md5').update(password).digest('hex');

// ✅ Strong hashing
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
```

### Session Management
```typescript
// Secure session configuration
app.register(fastifySession, {
  secret: process.env.SESSION_SECRET,
  cookie: {
    secure: true, // HTTPS only
    httpOnly: true, // No JS access
    sameSite: 'strict', // CSRF protection
    maxAge: 1800000 // 30 minutes
  }
});
```

## Step 4: API Security Audit

### Rate Limiting Check
```typescript
// Ensure rate limiting is implemented
app.register(fastifyRateLimit, {
  max: 100, // requests
  timeWindow: '1 minute',
  ban: 5, // ban after 5 429s
  skipSuccessfulRequests: false
});
```

### CORS Configuration
```typescript
// ❌ Too permissive
app.register(cors, { origin: '*' });

// ✅ Restrictive CORS
app.register(cors, {
  origin: (origin, cb) => {
    const allowedOrigins = ['https://app.example.com'];
    if (!origin || allowedOrigins.includes(origin)) {
      cb(null, true);
    } else {
      cb(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
});
```

### Input Validation
```typescript
// Comprehensive input validation
const schema = {
  body: {
    type: 'object',
    properties: {
      email: { 
        type: 'string', 
        format: 'email',
        maxLength: 255
      },
      age: { 
        type: 'integer',
        minimum: 0,
        maximum: 150
      }
    },
    required: ['email'],
    additionalProperties: false // Reject extra fields
  }
};
```

## Step 5: Security Headers Audit

### Implement Security Headers
```typescript
import helmet from '@fastify/helmet';

app.register(helmet, {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
});
```

### Custom Security Headers
```typescript
app.addHook('onSend', async (request, reply) => {
  reply.header('X-Frame-Options', 'DENY');
  reply.header('X-Content-Type-Options', 'nosniff');
  reply.header('Referrer-Policy', 'strict-origin-when-cross-origin');
  reply.header('Permissions-Policy', 'geolocation=(), microphone=()');
});
```

## Step 6: Database Security Audit

### Connection Security
```typescript
// ❌ Insecure connection
const db = knex({
  client: 'postgresql',
  connection: 'postgresql://user:pass@localhost/db'
});

// ✅ Secure connection
const db = knex({
  client: 'postgresql',
  connection: {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: true }
  }
});
```

### Query Parameterization
```bash
# Scan for raw SQL queries
grep -r "db.raw\|query(" src/ --include="*.ts" --include="*.js"

# Check for proper parameterization
```

## Step 7: Secrets Management Audit

### Environment Variables Check
```bash
# Check for hardcoded secrets
grep -r "password\|secret\|key\|token" src/ --include="*.ts" | grep -v "process.env"

# Scan for sensitive data
truffleHog filesystem ./

# Use git-secrets
git secrets --scan
```

### Secure Configuration
```typescript
// Use dotenv with validation
import { config } from 'dotenv';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  JWT_SECRET: z.string().min(32),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url()
});

const env = envSchema.parse(process.env);
```

## Step 8: Logging and Monitoring Audit

### Sensitive Data in Logs
```typescript
// ❌ Logging sensitive data
logger.info('User login', { email, password });

// ✅ Safe logging
logger.info('User login', { 
  email, 
  ip: request.ip,
  userAgent: request.headers['user-agent']
});
```

### Security Event Logging
```typescript
// Log security events
app.addHook('onRequest', async (request, reply) => {
  if (request.url.includes('admin')) {
    logger.warn('Admin access attempt', {
      ip: request.ip,
      url: request.url,
      user: request.user?.id
    });
  }
});
```

## Step 9: File Upload Security

### File Validation
```typescript
const uploadOptions = {
  limits: {
    fieldNameSize: 100,
    fieldSize: 1000000, // 1MB
    fields: 10,
    fileSize: 5000000, // 5MB
    files: 1,
  },
  fileFilter: (req, file, cb) => {
    // Check file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    if (!allowedTypes.includes(file.mimetype)) {
      cb(new Error('Invalid file type'), false);
      return;
    }
    
    // Check file extension
    const ext = path.extname(file.originalname).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif'].includes(ext)) {
      cb(new Error('Invalid file extension'), false);
      return;
    }
    
    cb(null, true);
  }
};
```

## Step 10: API Penetration Testing

### Automated Security Testing
```bash
# OWASP ZAP API Scan
docker run -t owasp/zap2docker-stable zap-api-scan.py \
  -t http://localhost:3000/openapi.json \
  -f openapi

# Burp Suite scan
# Configure and run through UI

# Nikto web scanner
nikto -h http://localhost:3000
```

### Manual Testing Checklist
```markdown
## Manual Security Testing

### Authentication
- [ ] Test with expired tokens
- [ ] Test with malformed tokens
- [ ] Test token from different user
- [ ] Test concurrent sessions
- [ ] Test account lockout

### Authorization
- [ ] Test accessing other users' data
- [ ] Test privilege escalation
- [ ] Test direct object references
- [ ] Test function level access

### Input Validation
- [ ] Test SQL injection in all inputs
- [ ] Test XSS in all outputs
- [ ] Test XXE in XML inputs
- [ ] Test command injection
- [ ] Test path traversal

### Business Logic
- [ ] Test race conditions
- [ ] Test workflow bypass
- [ ] Test negative amounts
- [ ] Test limit bypass
```

## Step 11: Security Report Generation

### Create Security Report
```bash
# Generate comprehensive report
mkdir -p reports/security/$(date +%Y%m%d)
cd reports/security/$(date +%Y%m%d)

# Collect all security scan results
npm audit --json > npm-audit.json
snyk test --json > snyk-report.json
npx retire --outputformat json > retire-report.json
```

### Report Template
```markdown
# Security Audit Report
Date: $(date)
Application: Backend API
Version: X.X.X

## Executive Summary
- Critical Issues: X
- High Issues: X
- Medium Issues: X
- Low Issues: X

## Vulnerability Details

### Critical Issues
1. Issue Name
   - Description
   - Impact
   - Remediation
   - Status

### Recommendations
1. Immediate actions required
2. Short-term improvements
3. Long-term security roadmap

## Compliance Status
- [ ] OWASP Top 10
- [ ] PCI DSS (if applicable)
- [ ] GDPR (if applicable)
- [ ] SOC2 (if applicable)
```

## Security Best Practices Checklist

```markdown
## Security Implementation Checklist

### Authentication & Authorization
- [ ] Strong password policy enforced
- [ ] MFA available/required
- [ ] Session management secure
- [ ] JWT properly implemented
- [ ] Role-based access control

### Data Protection
- [ ] Data encrypted at rest
- [ ] Data encrypted in transit
- [ ] PII properly handled
- [ ] Secrets in secure vault
- [ ] Backups encrypted

### API Security
- [ ] Rate limiting implemented
- [ ] Input validation comprehensive
- [ ] Output encoding proper
- [ ] CORS properly configured
- [ ] API versioning secure

### Infrastructure
- [ ] HTTPS enforced
- [ ] Security headers set
- [ ] Firewall rules strict
- [ ] Ports minimized
- [ ] Updates automated

### Monitoring & Response
- [ ] Security logging enabled
- [ ] Alerts configured
- [ ] Incident response plan
- [ ] Regular security reviews
- [ ] Penetration testing scheduled
```