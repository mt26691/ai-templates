# Setup Project - Infrastructure (Kubernetes)

This command guides you through setting up a new project or onboarding to an existing project.

## Prerequisites

- Node.js (v18+ recommended)
- npm or yarn
- Git
- Database client (PostgreSQL/MySQL/MongoDB)
- Redis (if used for caching)
- Docker (optional but recommended)

## Step 1: Clone and Initial Setup

### New Project Setup
```bash
# Clone repository
git clone <repository-url>
cd <project-name>

# Or create new project
npm init fastify-app@latest <project-name>
cd <project-name>
```

### Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

Required environment variables:
```env
# Application
NODE_ENV=development
PORT=3000
HOST=0.0.0.0
LOG_LEVEL=debug

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10

# Redis (if applicable)
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRY=7d

# External Services
API_KEY=your-api-key
WEBHOOK_SECRET=your-webhook-secret

# Monitoring
SENTRY_DSN=your-sentry-dsn
```

## Step 2: Install Dependencies

```bash
# Install dependencies
npm install

# Install dev dependencies if needed
npm install --save-dev

# Audit dependencies for vulnerabilities
npm audit

# Fix vulnerabilities if any
npm audit fix
```

## Step 3: Database Setup

### PostgreSQL Setup
```bash
# Create database
createdb <database-name>

# Run migrations
npm run migrate:latest

# Run seeds (development only)
npm run seed:run
```

### MongoDB Setup
```bash
# Ensure MongoDB is running
mongod --version

# Create database collections
npm run db:setup
```

### Verify Database Connection
```bash
# Test database connection
npm run db:test
```

## Step 4: Git Configuration

```bash
# Set up git hooks
npm run prepare

# Configure git user (if not global)
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Set up commit signing (optional)
git config commit.gpgsign true
git config user.signingkey YOUR_GPG_KEY
```

### Install Git Hooks
```bash
# Install husky
npx husky install

# Add pre-commit hook
npx husky add .husky/pre-commit "npm run lint && npm test"

# Add commit-msg hook for conventional commits
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
```

## Step 5: IDE Configuration

### VS Code Settings
Create `.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "files.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.git": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/coverage": true
  }
}
```

### VS Code Extensions
Create `.vscode/extensions.json`:
```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-typescript-tslint-plugin",
    "streetsidesoftware.code-spell-checker",
    "wayou.vscode-todo-highlight",
    "humao.rest-client"
  ]
}
```

## Step 6: Verify Setup

### Run Tests
```bash
# Run unit tests
npm test

# Run integration tests
npm run test:integration

# Check code coverage
npm run test:coverage
```

### Run Linters
```bash
# ESLint
npm run lint

# TypeScript check
npm run type-check

# Prettier check
npm run format:check
```

### Start Development Server
```bash
# Start with hot reload
npm run dev

# Verify server is running
curl http://localhost:3000/health
```

## Step 7: Project Structure Understanding

```
project-root/
├── src/
│   ├── app.ts              # Fastify app setup
│   ├── server.ts           # Server entry point
│   ├── config/             # Configuration files
│   ├── plugins/            # Fastify plugins
│   ├── routes/             # Route definitions
│   ├── services/           # Business logic
│   ├── models/             # Data models
│   ├── utils/              # Utility functions
│   └── types/              # TypeScript types
├── tests/
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   └── fixtures/           # Test data
├── scripts/                # Utility scripts
├── migrations/             # Database migrations
├── docs/                   # Documentation
└── docker/                 # Docker configurations
```

## Step 8: Documentation Review

```bash
# Generate initial documentation
npm run docs:generate

# Key documents to review
cat README.md
cat CONTRIBUTING.md
cat docs/API.md
cat docs/ARCHITECTURE.md
```

## Step 9: Local Development Tools

### Docker Setup (Optional)
```bash
# Start all services
docker-compose up -d

# Verify services
docker-compose ps

# View logs
docker-compose logs -f
```

### Database GUI Tools
- PostgreSQL: pgAdmin, TablePlus, DBeaver
- MongoDB: MongoDB Compass, Robo 3T
- Redis: RedisInsight, Redis Commander

## Step 10: Final Checklist

```markdown
## Setup Verification Checklist

### Environment
- [ ] Node.js version matches .nvmrc
- [ ] All environment variables configured
- [ ] Database connection successful
- [ ] Redis connection successful (if used)

### Code Quality
- [ ] ESLint running without errors
- [ ] TypeScript compiling successfully
- [ ] Prettier formatting configured
- [ ] Git hooks installed

### Testing
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Test coverage meets threshold
- [ ] E2E tests configured (if applicable)

### Development Server
- [ ] Server starts without errors
- [ ] Hot reload working
- [ ] API documentation accessible
- [ ] Health endpoint responding

### IDE
- [ ] VS Code extensions installed
- [ ] Debugging configuration working
- [ ] Code completion functioning
- [ ] Linting showing in editor
```

## Common Issues and Solutions

### Port Already in Use
```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Database Connection Failed
```bash
# Check PostgreSQL status
pg_isready

# Check MongoDB status
mongod --version

# Test connection string
npm run db:test-connection
```

### Node Version Mismatch
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Use project Node version
nvm use
```

## Next Steps

1. Review existing code patterns
2. Familiarize yourself with API routes
3. Check current test coverage
4. Review recent PRs for context
5. Set up personal development branch
6. Join team communication channels