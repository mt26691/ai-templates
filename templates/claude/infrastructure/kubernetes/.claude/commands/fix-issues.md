# Fix GitHub Issues - Infrastructure (Kubernetes)

This command helps you systematically fix GitHub issues for infrastructure with proper planning, documentation, and testing.

## Step 0: Setup and Issue Selection

### Prerequisites
- Ensure `gh` CLI is installed and authenticated
- kubectl installed and configured
- Helm installed (if using Helm charts)
- Access to cloud provider credentials
- Current directory should be the project root
- Git repository should be clean

### Select Issue
```bash
# List open issues assigned to you
gh issue list --assignee @me --label infrastructure

# View specific issue details
gh issue view <issue-number>

# Assign yourself to an issue
gh issue edit <issue-number> --add-assignee @me
```

## Step 1: Planning

### Analyze the Issue
1. Read the issue description thoroughly
2. Identify affected infrastructure components
3. Assess security implications
4. Evaluate cost impact
5. Plan rollback strategy

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
[Describe the infrastructure issue]

## Proposed Solution
[Outline your approach]

## Affected Resources
- [ ] Resource Type 1
- [ ] Resource Type 2

## Security Considerations
- [ ] IAM changes
- [ ] Network security
- [ ] Data encryption

## Cost Impact
- Current estimated cost: $X/month
- New estimated cost: $Y/month
- Delta: $Z/month

## Rollback Plan
1. Step 1
2. Step 2

## Testing Strategy
- Terraform plan review
- Staging environment validation
- Production deployment checklist
```

## Step 2: Create Feature Branch

```bash
# Create and checkout feature branch
git checkout -b fix/<issue-number>-<brief-description>

# Example
git checkout -b fix/123-vpc-security-group
```

## Step 3: Implementation

### Infrastructure-Specific Guidelines

1. **Terraform Best Practices**
   - Use consistent naming conventions
   - Leverage existing modules
   - Pin provider versions
   - Use appropriate data sources

2. **State Management**
   - Ensure remote state is configured
   - Use state locking
   - Plan state migrations carefully

3. **Security**
   - Never hardcode secrets
   - Use least privilege principle
   - Enable encryption at rest
   - Configure proper network segmentation

## Step 4: Testing

### Kubernetes Validation
```bash
# Validate YAML syntax
kubectl apply --dry-run=client -f .

# Lint Kubernetes manifests
kubeval **/*.yaml

# Policy validation with OPA
opa eval -d policies/ -i manifest.yaml
```

### Security Scanning
```bash
# Run kubesec for security issues
kubesec scan manifest.yaml

# Run Polaris for best practices
polaris audit --format yaml

# Review IAM policies
# Custom script or tool for IAM analysis
```

### Plan Review
```bash
# Preview changes with kubectl diff
kubectl diff -f .

# For Helm charts
helm diff upgrade <release-name> <chart> --values values.yaml

# Generate rendered manifests
kubectl kustomize . > rendered.yaml
```

### Testing Checklist
```markdown
## Pre-deployment Checklist

### Code Quality
- [ ] terraform fmt applied
- [ ] terraform validate passes
- [ ] No tflint warnings
- [ ] Variables documented

### Security
- [ ] tfsec scan clean
- [ ] No hardcoded secrets
- [ ] IAM permissions reviewed
- [ ] Network rules validated

### Plan Review
- [ ] No unexpected resource deletions
- [ ] Resource naming correct
- [ ] Tags properly applied
- [ ] Cost impact acceptable
```

### Staging Environment Test
```bash
# Switch to staging workspace
terraform workspace select staging

# Apply to staging
terraform apply -auto-approve

# Run validation tests
./scripts/validate-infrastructure.sh staging

# Document results
echo "Staging validation: $(date)" >> docs/issues/<issue-number>/staging-test.log
```

## Step 5: Documentation

### Create Implementation Documentation
```bash
# Create comprehensive documentation
touch docs/issues/<issue-number>/implementation.md
touch docs/issues/<issue-number>/architecture-diagram.md
```

Include:
- Architecture diagrams (before/after)
- Security group rules
- IAM policy changes
- Resource dependencies
- Monitoring setup
- Backup procedures

### Update Project Documentation
- Update infrastructure README
- Update runbooks
- Update disaster recovery plans
- Update cost tracking

## Step 6: Create Pull Request

```bash
# Push branch
git push -u origin fix/<issue-number>-<brief-description>

# Create PR with detailed information
gh pr create \
  --title "Fix #<issue-number>: <brief description>" \
  --body "Fixes #<issue-number>

## Changes
- Change 1
- Change 2

## Terraform Plan Summary
\`\`\`
Plan: X to add, Y to change, Z to destroy
\`\`\`

## Security Review
- [x] tfsec scan passed
- [x] Checkov compliance check passed
- [x] IAM permissions follow least privilege
- [x] No exposed secrets

## Testing
- [x] Terraform fmt/validate/tflint passed
- [x] Staging environment tested successfully
- [x] Rollback plan documented
- [x] Cost impact analyzed

## Documentation
- [x] Architecture diagrams updated
- [x] Runbooks updated
- [x] Implementation notes in /docs/issues/<issue-number>/

## Deployment Plan
1. Apply during maintenance window
2. Monitor for 30 minutes post-deployment
3. Run smoke tests
4. Update monitoring dashboards"
```

## Step 7: Production Deployment

### Pre-deployment
```bash
# Create backup of current state
terraform state pull > backup-state-$(date +%Y%m%d-%H%M%S).json

# Final plan review
terraform plan

# Notify team
echo "Deploying infrastructure fix #<issue-number> at $(date)"
```

### Deployment
```bash
# Apply with confirmation
terraform apply

# Or for CI/CD
terraform apply -auto-approve
```

### Post-deployment
```bash
# Verify resources
terraform state list
terraform output

# Run smoke tests
./scripts/smoke-tests.sh production

# Update monitoring
# Configure alerts for new resources
```

## Step 8: Post-Implementation

### After Successful Deployment
```bash
# Switch back to main branch
git checkout main
git pull

# Delete local feature branch
git branch -d fix/<issue-number>-<brief-description>

# Archive implementation docs
mkdir -p docs/issues/completed
mv docs/issues/<issue-number> docs/issues/completed/

# Update infrastructure inventory
./scripts/update-inventory.sh
```

### Close Issue
```bash
# Close issue with deployment details
gh issue close <issue-number> \
  --comment "Fixed in PR #<pr-number>. 
  
Deployment completed at $(date)
- Resources modified: X
- No service disruption
- Documentation: /docs/issues/completed/<issue-number>/
- Monitoring: [dashboard-link]"
```

## Best Practices

1. **Change Management**
   - Always test in staging first
   - Plan maintenance windows
   - Have rollback ready
   - Monitor after deployment

2. **Security**
   - Regular security scans
   - Rotate credentials regularly
   - Use encryption everywhere
   - Follow cloud provider best practices

3. **Cost Optimization**
   - Tag all resources properly
   - Review cost before applying
   - Use appropriate instance sizes
   - Enable auto-scaling where applicable

4. **Documentation**
   - Keep diagrams up-to-date
   - Document all manual steps
   - Maintain runbooks
   - Record lessons learned

5. **State Management**
   - Never modify state manually
   - Always backup before major changes
   - Use workspaces for environments
   - Enable state locking