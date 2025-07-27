# Fix GitHub Issues - Frontend (Next.js)

This command helps you systematically fix GitHub issues with proper planning, documentation, and testing including visual tests.

## Step 0: Setup and Issue Selection

### Prerequisites
- Ensure `gh` CLI is installed and authenticated
- Current directory should be the project root
- Git repository should be clean (no uncommitted changes)
- Development server should be running for visual testing

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
2. Identify affected components/pages
3. Determine UI/UX changes needed
4. Plan visual regression testing

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
- [ ] Component/Page 1
- [ ] Component/Page 2

## Visual Changes
- [ ] Desktop view
- [ ] Mobile view
- [ ] Dark mode compatibility
- [ ] Accessibility considerations

## Testing Strategy
- Unit tests for [components]
- Integration tests for [user flows]
- Visual regression tests for [pages/components]

## Implementation Steps
1. Step 1
2. Step 2
```

## Step 2: Create Feature Branch

```bash
# Create and checkout feature branch
git checkout -b fix/<issue-number>-<brief-description>

# Example
git checkout -b fix/123-navbar-responsive-bug
```

## Step 3: Implementation

### Frontend-Specific Guidelines

1. **Component Changes**
   - Follow existing component patterns
   - Maintain TypeScript types
   - Use existing design system/UI library
   - Ensure responsive design

2. **State Management**
   - Update Redux/Context/Zustand stores if needed
   - Handle loading and error states
   - Optimize re-renders

3. **Styling**
   - Use existing CSS/Tailwind patterns
   - Maintain theme consistency
   - Test dark mode if supported

4. **Performance**
   - Lazy load components when appropriate
   - Optimize images and assets
   - Check bundle size impact

## Step 4: Testing

### Unit Tests
```bash
# Run unit tests
npm test

# Run specific test file
npm test -- ComponentName.test.tsx

# Run tests in watch mode
npm test -- --watch

# Update snapshots if needed
npm test -- -u
```

Unit test requirements:
- Test component rendering
- Test user interactions
- Test props and state changes
- Test error boundaries

### Integration Tests
```bash
# Run Cypress/Playwright tests
npm run test:e2e

# Run specific test
npm run test:e2e -- --spec "cypress/e2e/issue-123.cy.ts"

# Run in headed mode for debugging
npm run test:e2e:headed
```

### Visual Testing

#### 1. Manual Visual Testing Checklist
```markdown
## Visual Testing Checklist

### Desktop (1920x1080)
- [ ] Chrome
- [ ] Firefox
- [ ] Safari
- [ ] Edge

### Tablet (768x1024)
- [ ] Portrait orientation
- [ ] Landscape orientation

### Mobile (375x667)
- [ ] iOS Safari
- [ ] Android Chrome

### Accessibility
- [ ] Keyboard navigation works
- [ ] Screen reader compatibility
- [ ] Color contrast passes WCAG AA
- [ ] Focus indicators visible

### Dark Mode (if applicable)
- [ ] All text readable
- [ ] Proper contrast maintained
- [ ] No broken styles
```

#### 2. Visual Regression Testing
```bash
# Take baseline screenshots
npm run test:visual:update

# Run visual regression tests
npm run test:visual

# Review visual diffs
npm run test:visual:report
```

#### 3. Storybook Testing (if applicable)
```bash
# Run Storybook
npm run storybook

# Run Storybook tests
npm run test:storybook

# Build Storybook for review
npm run build-storybook
```

### Example Test Structure
```typescript
// Unit Test Example
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button Component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });
  
  it('handles click events', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    fireEvent.click(screen.getByText('Click me'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});

// E2E Test Example
describe('User Authentication Flow', () => {
  it('should login successfully', () => {
    cy.visit('/login');
    cy.get('[data-testid="email-input"]').type('user@example.com');
    cy.get('[data-testid="password-input"]').type('password123');
    cy.get('[data-testid="login-button"]').click();
    cy.url().should('include', '/dashboard');
  });
});
```

## Step 5: Documentation

### Create Implementation Documentation
```bash
# Create implementation notes with screenshots
mkdir -p docs/issues/<issue-number>/screenshots
touch docs/issues/<issue-number>/implementation.md
```

Include:
- Before/after screenshots
- Component API changes
- Performance impact
- Browser compatibility notes
- Accessibility improvements

### Capture Screenshots
```bash
# Use built-in screenshot tool or
# Take screenshots programmatically during tests
```

### Update Project Documentation
- Update component documentation
- Update Storybook stories
- Add usage examples
- Update style guide if needed

## Step 6: Create Pull Request

```bash
# Push branch
git push -u origin fix/<issue-number>-<brief-description>

# Create PR with issue reference and visuals
gh pr create \
  --title "Fix #<issue-number>: <brief description>" \
  --body "Fixes #<issue-number>

## Changes
- Change 1
- Change 2

## Visual Changes
### Before
![Before](link-to-before-screenshot)

### After
![After](link-to-after-screenshot)

## Testing
- [x] Unit tests added/updated
- [x] E2E tests added/updated
- [x] Visual regression tests passing
- [x] Manual visual testing completed
- [x] Tested on mobile devices
- [x] Accessibility tested

## Browser Testing
- [x] Chrome
- [x] Firefox
- [x] Safari
- [x] Edge

## Documentation
- [x] Component docs updated
- [x] Storybook stories updated
- [x] Screenshots in /docs/issues/<issue-number>/"
```

## Step 7: Post-Implementation

### After PR Approval and Merge
```bash
# Switch back to main branch
git checkout main
git pull

# Delete local feature branch
git branch -d fix/<issue-number>-<brief-description>

# Update visual regression baselines if needed
npm run test:visual:update

# Archive implementation docs
mkdir -p docs/issues/completed
mv docs/issues/<issue-number> docs/issues/completed/
```

### Close Issue
```bash
# Close issue with comment
gh issue close <issue-number> \
  --comment "Fixed in PR #<pr-number>. Visual changes documented in /docs/issues/completed/<issue-number>/"
```

## Best Practices

1. **Commit Messages**
   - Use conventional commits: `fix: resolve navbar responsive issue`
   - Reference issue: `fix: resolve navbar issue (#123)`

2. **Visual Testing**
   - Always test responsive design
   - Check dark mode compatibility
   - Verify animations and transitions
   - Test with real content, not just lorem ipsum

3. **Performance**
   - Check Lighthouse scores before/after
   - Monitor bundle size changes
   - Profile component render times

4. **Accessibility**
   - Run axe-core tests
   - Test with keyboard only
   - Verify screen reader announcements
   - Check focus management

5. **Code Review**
   - Include screenshots in PR
   - Link to deployed preview if available
   - Document any visual compromises
   - Get design approval if needed