# Pull Request Review Guide - Infrastructure (Kubernetes)

This command provides a comprehensive checklist and process for reviewing pull requests effectively.

## Step 1: Initial PR Assessment

### Quick Overview
```bash
# Get PR information
gh pr view <pr-number>

# Check PR diff statistics
gh pr diff <pr-number> --stat

# View files changed
gh pr view <pr-number> --json files --jq '.files[].path'

# Check PR checks status
gh pr checks <pr-number>
```

### PR Size Analysis
```bash
# Check if PR is too large
CHANGES=$(gh pr diff <pr-number> --stat | tail -1)
echo "PR Size: $CHANGES"

# Recommendation:
# - Small: < 100 lines (quick review)
# - Medium: 100-500 lines (normal review)
# - Large: 500-1000 lines (careful review)
# - Too Large: > 1000 lines (consider splitting)
```

## Step 2: Code Review Checklist

### 1. General Code Quality
```markdown
## Code Quality Checklist

### Clean Code
- [ ] Code is self-documenting with clear naming
- [ ] No commented-out code
- [ ] No console.log or debug statements
- [ ] DRY principle followed (no duplicated code)
- [ ] SOLID principles applied where appropriate

### TypeScript/JavaScript
- [ ] Proper TypeScript types (no `any` without justification)
- [ ] Interfaces over type aliases for objects
- [ ] Enums used appropriately
- [ ] No TypeScript errors or warnings

### Code Style
- [ ] Consistent with project style guide
- [ ] Proper indentation and formatting
- [ ] Meaningful variable/function names
- [ ] Comments explain "why" not "what"
```

### 2. Architecture & Design
```markdown
## Architecture Review

### Design Patterns
- [ ] Appropriate design patterns used
- [ ] No over-engineering
- [ ] Separation of concerns maintained
- [ ] Dependencies properly injected

### API Design
- [ ] RESTful principles followed
- [ ] Consistent endpoint naming
- [ ] Proper HTTP status codes
- [ ] Clear request/response contracts

### Database
- [ ] Efficient queries (no N+1 problems)
- [ ] Proper indexes considered
- [ ] Transactions used where needed
- [ ] Connection pooling configured
```

### 3. Security Review
```markdown
## Security Checklist

### Input Validation
- [ ] All inputs validated
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] Path traversal prevention

### Authentication & Authorization
- [ ] Proper authentication checks
- [ ] Authorization implemented correctly
- [ ] No hardcoded credentials
- [ ] Secrets properly managed

### Data Protection
- [ ] Sensitive data encrypted
- [ ] PII handled appropriately
- [ ] Proper data sanitization
- [ ] Secure communication (HTTPS)
```

## Step 3: Automated Checks

### Run Automated Tests Locally
```bash
# Checkout PR branch
gh pr checkout <pr-number>

# Install dependencies
npm ci

# Run all checks
npm run lint
npm run type-check
npm test
npm run test:integration
npm audit
```

### Performance Impact Check
```bash
# Build and check bundle size
npm run build
du -sh dist/

# Run performance benchmarks
npm run benchmark

# Check for new dependencies
npm list --depth=0 | wc -l
```

## Step 4: Functional Review

### Testing Coverage
```bash
# Check test coverage
npm run test:coverage

# Review coverage report
open coverage/lcov-report/index.html

# Ensure new code is tested
git diff main --name-only | grep -E '\.(ts|js)$' | while read file; do
  echo "Checking tests for: $file"
  test_file="${file/.ts/.test.ts}"
  test_file="${test_file/.js/.test.js}"
  if [ ! -f "$test_file" ]; then
    echo "⚠️  No test file found for: $file"
  fi
done
```

### Manual Testing Script
```bash
#!/bin/bash
# manual-test-pr.sh

echo "Starting manual test for PR #$1"

# Start the application
npm run dev &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Run manual test scenarios
echo "Testing new endpoints..."
# Add specific curl commands for new endpoints

# Stop server
kill $SERVER_PID

echo "Manual testing completed"
```

## Step 5: Code-Specific Reviews

### Database Migration Review
```sql
-- Check migration safety
-- Look for:
-- 1. Locks on large tables
-- 2. Index creation without CONCURRENTLY
-- 3. NOT NULL without default on existing columns
-- 4. Dropping columns without feature flag

-- Test migration locally
npx knex migrate:latest
npx knex migrate:rollback
```

### API Endpoint Review
```typescript
// Check for:
// 1. Proper input validation
// 2. Authentication/authorization
// 3. Rate limiting
// 4. Error handling
// 5. Response schema matching documentation

// Example review comment:
```
⚠️ This endpoint is missing rate limiting. Consider adding:
```typescript
preHandler: fastify.rateLimit({
  max: 100,
  timeWindow: '1 minute'
})
```

### Performance Critical Code
```typescript
// Look for:
// 1. Unnecessary loops
// 2. Inefficient algorithms
// 3. Memory leaks
// 4. Blocking operations

// Example review comment:
```
🔍 This could be optimized using a Map for O(1) lookup:
```typescript
const userMap = new Map(users.map(u => [u.id, u]));
const user = userMap.get(userId);
```

## Step 6: Review Comments

### Effective Review Comments

#### Constructive Feedback Template
```markdown
**Issue**: [Brief description of the problem]

**Impact**: [Why this matters - security, performance, maintainability]

**Suggestion**:
```typescript
// Proposed code change
```

**Reference**: [Link to documentation or best practice]
```

#### Comment Categories
```markdown
🚨 **Critical**: Must be fixed before merge (security, data loss)
⚠️ **Important**: Should be fixed (bugs, performance)
💡 **Suggestion**: Consider improving (style, optimization)
❓ **Question**: Need clarification
👍 **Praise**: Good implementation
```

### Example Comments

#### Security Issue
```markdown
🚨 **Critical Security Issue**: SQL Injection vulnerability

This query is vulnerable to SQL injection:
```typescript
const users = await db.raw(`SELECT * FROM users WHERE name = '${userName}'`);
```

Please use parameterized queries:
```typescript
const users = await db.raw('SELECT * FROM users WHERE name = ?', [userName]);
```
```

#### Performance Concern
```markdown
⚠️ **Performance**: N+1 query problem detected

This will execute one query per user:
```typescript
for (const user of users) {
  user.posts = await db('posts').where('user_id', user.id);
}
```

Consider using a join or batch loading:
```typescript
const userIds = users.map(u => u.id);
const posts = await db('posts').whereIn('user_id', userIds);
const postsByUser = groupBy(posts, 'user_id');
users.forEach(user => {
  user.posts = postsByUser[user.id] || [];
});
```
```

## Step 7: Testing the PR

### Integration Test Suite
```bash
#!/bin/bash
# test-pr-integration.sh

# Set up test environment
export NODE_ENV=test
export DATABASE_URL=postgresql://localhost/test_db

# Reset test database
npm run db:test:reset

# Run integration tests
npm run test:integration

# Run E2E tests
npm run test:e2e

# Load testing
npm run test:load
```

### Regression Testing
```markdown
## Regression Test Checklist

### Core Functionality
- [ ] User registration/login works
- [ ] Main API endpoints respond correctly
- [ ] Database queries perform well
- [ ] Background jobs execute

### Edge Cases
- [ ] Error handling works properly
- [ ] Rate limiting functions
- [ ] Timeout handling correct
- [ ] Concurrent request handling
```

## Step 8: Documentation Review

### Documentation Checklist
```markdown
## Documentation Requirements

### Code Documentation
- [ ] Complex functions have JSDoc comments
- [ ] API endpoints documented
- [ ] Type definitions clear
- [ ] README updated if needed

### API Documentation
- [ ] OpenAPI/Swagger updated
- [ ] New endpoints documented
- [ ] Breaking changes noted
- [ ] Examples provided

### Changelog
- [ ] CHANGELOG.md updated
- [ ] Migration guide for breaking changes
- [ ] Version bump appropriate
```

### Generate Documentation
```bash
# Generate and review API docs
npm run docs:generate
npm run docs:serve

# Check for undocumented endpoints
npm run docs:check
```

## Step 9: Final Review Steps

### Pre-Approval Checklist
```markdown
## Final Review Checklist

### Must Have
- [ ] All CI checks passing
- [ ] No security vulnerabilities
- [ ] Tests adequate (coverage > 80%)
- [ ] No performance regressions
- [ ] Documentation complete

### Should Have
- [ ] Code follows style guide
- [ ] No code smells
- [ ] Efficient implementation
- [ ] Clear commit messages

### Nice to Have
- [ ] Refactoring opportunities noted
- [ ] Future improvements suggested
- [ ] Learning shared with team
```

### Approval Comment Template
```markdown
## ✅ Approved

Great work! The implementation is solid and well-tested.

**Strengths:**
- Clean, readable code
- Comprehensive test coverage
- Good error handling

**Minor suggestions for future:**
- Consider adding metrics for the new endpoint
- Could benefit from caching in high-traffic scenarios

No blockers - ready to merge! 🚀
```

## Step 10: Post-Review Actions

### After Approval
```bash
# Ensure branch is up to date
gh pr merge <pr-number> --auto --squash

# Or manually:
git checkout main
git pull
gh pr checkout <pr-number>
git rebase main
git push --force-with-lease

# Monitor deployment
watch -n 5 'kubectl get pods -n production'
```

### Knowledge Sharing
```markdown
## Share Learning

### Team Update
Post in team channel about:
- New patterns introduced
- Gotchas discovered
- Performance improvements
- Security enhancements

### Documentation
Update team wiki with:
- New best practices
- Common review issues
- Helpful review techniques
```

## Review Best Practices

### DO's
- Be constructive and specific
- Provide code examples
- Acknowledge good implementations
- Focus on the code, not the person
- Respond promptly to reviews

### DON'Ts
- Don't nitpick minor style issues (use linters)
- Don't approve with unresolved concerns
- Don't review when tired or rushed
- Don't assume malicious intent
- Don't forget to praise good code

## Quick Review Commands

```bash
# Review PR locally
gh pr checkout <pr-number>

# Run all checks
npm run ci

# Check specific file history
git log -p path/to/file.ts

# Find potential issues
grep -r "TODO\|FIXME\|XXX\|HACK" .

# Check for secrets
git diff main | grep -iE "password|secret|key|token"

# Performance check
npm run build && npm run benchmark

# Security scan
npm audit && npm run security-scan
```