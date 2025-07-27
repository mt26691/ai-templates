# Fix GitHub Issues - Backend (Express)

This command helps you systematically fix GitHub issues with proper planning, documentation, and testing.

## Step 0: Setup and Issue Selection

### Prerequisites
- Ensure `gh` CLI is installed and authenticated
- Current directory should be the project root
- Git repository should be clean (no uncommitted changes)

### Select Issue
```bash
# List open issues assigned to you
gh issue list --assignee @me

# View specific issue details
gh issue view <issue-number>

# Assign yourself to an issue
gh issue edit <issue-number> --add-assignee @me
```

## Step 1: Planning

### Analyze the Issue
1. Read the issue description thoroughly
2. Identify the scope of changes needed
3. List affected components/modules
4. Determine testing requirements

### Create Planning Document
```bash
# Create planning document
mkdir -p docs/issues/<issue-number>
touch docs/issues/<issue-number>/plan.md
```

Planning document template:
```markdown
# Issue #<number>: <title>

## Problem Statement
[Describe the issue]

## Proposed Solution
[Outline your approach]

## Affected Components
- [ ] Component/Module 1
- [ ] Component/Module 2

## Testing Strategy
- Unit tests for [components]
- Integration tests for [workflows]

## Implementation Steps
1. Step 1
2. Step 2
```

## Step 2: Create Feature Branch

```bash
# Create and checkout feature branch
git checkout -b fix/<issue-number>-<brief-description>

# Example
git checkout -b fix/123-user-auth-bug
```

## Step 3: Implementation

### Backend-Specific Guidelines

1. **Code Changes**
   - Follow existing code patterns
   - Maintain type safety
   - Add proper error handling
   - Update OpenAPI/Swagger specs if needed

2. **Database Changes**
   - Create migration files if schema changes
   - Update seed data if necessary

3. **API Changes**
   - Update route definitions
   - Modify DTOs/schemas
   - Update API documentation

## Step 4: Testing

### Unit Tests
```bash
# Run unit tests
npm test

# Run specific test file
npm test -- path/to/test.spec.ts

# Run tests in watch mode
npm test -- --watch
```

Unit test requirements:
- Test all new functions/methods
- Test edge cases and error scenarios
- Maintain or improve code coverage
- Mock external dependencies

### Integration Tests
```bash
# Run integration tests
npm run test:integration

# Run specific integration test
npm run test:integration -- path/to/integration.test.ts
```

Integration test requirements:
- Test complete API endpoints
- Test database interactions
- Test authentication/authorization flows
- Test error responses

### Example Test Structure
```typescript
// Unit Test Example
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a new user', async () => {
      // Test implementation
    });
    
    it('should throw error for duplicate email', async () => {
      // Test implementation
    });
  });
});

// Integration Test Example
describe('POST /api/users', () => {
  it('should create user with valid data', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/users',
      payload: { /* user data */ }
    });
    
    expect(response.statusCode).toBe(201);
  });
});
```

## Step 5: Documentation

### Create Implementation Documentation
```bash
# Create implementation notes
touch docs/issues/<issue-number>/implementation.md
```

Include:
- Technical decisions made
- Challenges encountered
- Performance considerations
- Security implications
- Future improvements

### Update Project Documentation
- Update README if needed
- Update API documentation
- Add code comments for complex logic
- Update changelog

## Step 6: Create Pull Request

```bash
# Push branch
git push -u origin fix/<issue-number>-<brief-description>

# Create PR with issue reference
gh pr create \
  --title "Fix #<issue-number>: <brief description>" \
  --body "Fixes #<issue-number>

## Changes
- Change 1
- Change 2

## Testing
- [x] Unit tests added/updated
- [x] Integration tests added/updated
- [x] All tests passing
- [x] Manual testing completed

## Documentation
- [x] Code comments added
- [x] API docs updated
- [x] Implementation notes in /docs/issues/<issue-number>/"
```

## Step 7: Post-Implementation

### After PR Approval and Merge
```bash
# Switch back to main branch
git checkout main
git pull

# Delete local feature branch
git branch -d fix/<issue-number>-<brief-description>

# Archive implementation docs
mkdir -p docs/issues/completed
mv docs/issues/<issue-number> docs/issues/completed/
```

### Close Issue
```bash
# Close issue with comment
gh issue close <issue-number> \
  --comment "Fixed in PR #<pr-number>. Documentation available in /docs/issues/completed/<issue-number>/"
```

## Best Practices

1. **Commit Messages**
   - Use conventional commits: `fix: resolve user authentication bug`
   - Reference issue: `fix: resolve auth bug (#123)`

2. **Testing**
   - Never skip tests
   - Add tests for bug fixes to prevent regression
   - Test edge cases

3. **Documentation**
   - Document "why" not just "what"
   - Include examples in docs
   - Keep docs up-to-date

4. **Code Review**
   - Self-review before requesting reviews
   - Address all feedback
   - Test after making review changes