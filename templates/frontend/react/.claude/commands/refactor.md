# Code Refactoring Guide - Frontend (React)

This command helps you systematically refactor code while maintaining functionality and improving quality.

## Step 1: Identify Refactoring Needs

### Code Smell Detection
```bash
# Run code analysis tools
npm run lint
npm run type-check

# Check code complexity
npx eslint --rule complexity src/

# Check for duplicate code
npx jscpd src/

# Generate code quality report
npm run code-quality
```

### Common Code Smells to Look For
- **Long Methods**: Functions > 50 lines
- **Large Classes**: Classes with > 300 lines
- **Too Many Parameters**: Functions with > 4 parameters
- **Duplicate Code**: Similar code blocks
- **Dead Code**: Unused variables/functions
- **Complex Conditionals**: Nested if/else > 3 levels
- **God Objects**: Classes doing too much

## Step 2: Create Refactoring Plan

### Document Current State
```bash
# Create refactoring documentation
mkdir -p docs/refactoring/<component-name>
touch docs/refactoring/<component-name>/plan.md
```

Refactoring plan template:
```markdown
# Refactoring Plan: <Component Name>

## Current Issues
1. Issue 1: Description
2. Issue 2: Description

## Proposed Changes
1. Change 1: Approach
2. Change 2: Approach

## Risk Assessment
- **Breaking Changes**: Yes/No
- **API Changes**: Yes/No
- **Database Changes**: Yes/No
- **Performance Impact**: Positive/Neutral/Negative

## Testing Strategy
- Existing tests to update
- New tests needed
- Performance benchmarks

## Rollback Plan
Steps to revert if issues arise
```

## Step 3: Setup Refactoring Branch

```bash
# Create refactoring branch
git checkout -b refactor/<component-name>

# Example
git checkout -b refactor/user-service-optimization
```

## Step 4: Common Refactoring Patterns

### 1. Extract Method
**Before:**
```typescript
async processOrder(order: Order) {
  // Validate order
  if (!order.items || order.items.length === 0) {
    throw new Error('Order must have items');
  }
  if (!order.customerId) {
    throw new Error('Customer ID required');
  }
  
  // Calculate total
  let total = 0;
  for (const item of order.items) {
    total += item.price * item.quantity;
  }
  
  // Apply discount
  if (order.discountCode) {
    const discount = await this.getDiscount(order.discountCode);
    total = total * (1 - discount.percentage / 100);
  }
  
  // Process payment
  const payment = await this.paymentService.charge(order.customerId, total);
  
  return { orderId: order.id, payment };
}
```

**After:**
```typescript
async processOrder(order: Order) {
  this.validateOrder(order);
  const total = await this.calculateOrderTotal(order);
  const payment = await this.processPayment(order.customerId, total);
  
  return { orderId: order.id, payment };
}

private validateOrder(order: Order): void {
  if (!order.items?.length) {
    throw new Error('Order must have items');
  }
  if (!order.customerId) {
    throw new Error('Customer ID required');
  }
}

private async calculateOrderTotal(order: Order): Promise<number> {
  const subtotal = this.calculateSubtotal(order.items);
  return this.applyDiscount(subtotal, order.discountCode);
}

private calculateSubtotal(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

private async applyDiscount(amount: number, discountCode?: string): Promise<number> {
  if (!discountCode) return amount;
  
  const discount = await this.getDiscount(discountCode);
  return amount * (1 - discount.percentage / 100);
}
```

### 2. Replace Conditional with Polymorphism
**Before:**
```typescript
class NotificationService {
  async send(notification: Notification) {
    if (notification.type === 'email') {
      await this.sendEmail(notification);
    } else if (notification.type === 'sms') {
      await this.sendSms(notification);
    } else if (notification.type === 'push') {
      await this.sendPush(notification);
    }
  }
}
```

**After:**
```typescript
interface NotificationStrategy {
  send(notification: Notification): Promise<void>;
}

class EmailNotificationStrategy implements NotificationStrategy {
  async send(notification: Notification): Promise<void> {
    // Email sending logic
  }
}

class SmsNotificationStrategy implements NotificationStrategy {
  async send(notification: Notification): Promise<void> {
    // SMS sending logic
  }
}

class NotificationService {
  private strategies: Map<string, NotificationStrategy> = new Map([
    ['email', new EmailNotificationStrategy()],
    ['sms', new SmsNotificationStrategy()],
    ['push', new PushNotificationStrategy()]
  ]);

  async send(notification: Notification) {
    const strategy = this.strategies.get(notification.type);
    if (!strategy) {
      throw new Error(`Unknown notification type: ${notification.type}`);
    }
    await strategy.send(notification);
  }
}
```

### 3. Extract Class
**Before:**
```typescript
class UserService {
  // User management
  async createUser(data: CreateUser) { }
  async updateUser(id: string, data: UpdateUser) { }
  async deleteUser(id: string) { }
  
  // Authentication
  async login(email: string, password: string) { }
  async logout(userId: string) { }
  async refreshToken(token: string) { }
  
  // Profile management
  async uploadAvatar(userId: string, file: Buffer) { }
  async updateProfile(userId: string, profile: Profile) { }
  async getProfile(userId: string) { }
}
```

**After:**
```typescript
class UserService {
  async createUser(data: CreateUser) { }
  async updateUser(id: string, data: UpdateUser) { }
  async deleteUser(id: string) { }
}

class AuthService {
  async login(email: string, password: string) { }
  async logout(userId: string) { }
  async refreshToken(token: string) { }
}

class ProfileService {
  async uploadAvatar(userId: string, file: Buffer) { }
  async updateProfile(userId: string, profile: Profile) { }
  async getProfile(userId: string) { }
}
```

### 4. Introduce Parameter Object
**Before:**
```typescript
async searchProducts(
  query: string,
  category: string,
  minPrice: number,
  maxPrice: number,
  sortBy: string,
  sortOrder: 'asc' | 'desc',
  page: number,
  limit: number
) { }
```

**After:**
```typescript
interface ProductSearchParams {
  query: string;
  category: string;
  priceRange: {
    min: number;
    max: number;
  };
  sort: {
    by: string;
    order: 'asc' | 'desc';
  };
  pagination: {
    page: number;
    limit: number;
  };
}

async searchProducts(params: ProductSearchParams) { }
```

## Step 5: Database Query Optimization

### Before:
```typescript
// N+1 query problem
const users = await db('users').select();
for (const user of users) {
  user.posts = await db('posts').where('user_id', user.id);
}
```

### After:
```typescript
// Single query with join
const users = await db('users')
  .leftJoin('posts', 'users.id', 'posts.user_id')
  .select('users.*', db.raw('json_agg(posts.*) as posts'))
  .groupBy('users.id');
```

## Step 6: Performance Profiling

### Before Refactoring
```bash
# Run performance benchmark
npm run benchmark -- --component=<component-name>

# Profile memory usage
node --inspect src/server.ts
# Use Chrome DevTools for profiling

# Save baseline metrics
npm run benchmark -- --save-baseline
```

### After Refactoring
```bash
# Compare performance
npm run benchmark -- --compare-baseline

# Generate performance report
npm run performance-report
```

## Step 7: Testing During Refactoring

### Ensure Test Coverage
```bash
# Check current coverage
npm run test:coverage

# Run tests continuously
npm test -- --watch

# Run specific test suite
npm test -- UserService
```

### Add Characterization Tests
```typescript
// Test existing behavior before refactoring
describe('UserService - Characterization Tests', () => {
  it('should maintain existing behavior for edge cases', () => {
    // Test current behavior, even if suboptimal
  });
});
```

## Step 8: Gradual Refactoring Strategies

### Strangler Fig Pattern
```typescript
// Step 1: Create new implementation alongside old
class UserServiceV2 {
  // New implementation
}

// Step 2: Route traffic gradually
class UserServiceProxy {
  constructor(
    private oldService: UserService,
    private newService: UserServiceV2,
    private featureFlag: FeatureFlag
  ) {}

  async getUser(id: string) {
    if (this.featureFlag.isEnabled('use-new-user-service')) {
      return this.newService.getUser(id);
    }
    return this.oldService.getUser(id);
  }
}

// Step 3: Remove old implementation after verification
```

### Branch by Abstraction
```typescript
// Step 1: Create abstraction
interface IUserRepository {
  findById(id: string): Promise<User>;
  save(user: User): Promise<void>;
}

// Step 2: Implement for current system
class LegacyUserRepository implements IUserRepository {
  // Current implementation
}

// Step 3: Create new implementation
class OptimizedUserRepository implements IUserRepository {
  // New implementation
}

// Step 4: Switch implementations via dependency injection
```

## Step 9: Code Quality Metrics

### Track Improvements
```bash
# Generate code quality metrics
npm run metrics

# Compare before/after
npm run metrics -- --compare=before.json

# Key metrics to track:
# - Cyclomatic complexity
# - Code coverage
# - Duplicate code percentage
# - Technical debt ratio
```

### Documentation Updates
```typescript
/**
 * @deprecated Use UserServiceV2.getUser() instead
 * Will be removed in version 3.0.0
 */
async getUser(id: string) {
  return this.userServiceV2.getUser(id);
}
```

## Step 10: Review and Merge

### Self-Review Checklist
```markdown
## Refactoring Review Checklist

### Functionality
- [ ] All tests pass
- [ ] No regression in features
- [ ] Performance improved or unchanged
- [ ] Error handling maintained

### Code Quality
- [ ] Reduced complexity
- [ ] Improved readability
- [ ] Better separation of concerns
- [ ] DRY principle applied

### Documentation
- [ ] Code comments updated
- [ ] API documentation current
- [ ] Deprecation notices added
- [ ] Migration guide written

### Testing
- [ ] Test coverage maintained/improved
- [ ] New tests for refactored code
- [ ] Integration tests pass
- [ ] Performance tests show improvement
```

## Common Pitfalls to Avoid

1. **Over-engineering**: Don't add complexity for future requirements
2. **Big Bang Refactoring**: Refactor incrementally
3. **Ignoring Tests**: Always maintain test coverage
4. **Performance Regression**: Profile before and after
5. **Breaking API Contracts**: Maintain backwards compatibility

## Tools and Resources

### Static Analysis
- ESLint with complexity rules
- SonarQube for code quality
- CodeClimate for maintainability

### Refactoring Tools
- VS Code refactoring features
- TypeScript compiler for safe refactoring
- AST-based tools for complex refactoring

### Performance Tools
- Clinic.js for Node.js profiling
- Artillery for load testing
- New Relic/DataDog for production monitoring