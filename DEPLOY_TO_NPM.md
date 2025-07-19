# 📦 Deploying to npm

This guide walks you through publishing the ai-templates package to npm.

## 📋 Pre-deployment Checklist

- [ ] All code is tested and working
- [ ] `package.json` has correct name and version
- [ ] README.md is complete and accurate
- [ ] LICENSE file exists
- [ ] All templates are included
- [ ] Build process works correctly

## 🚀 Step-by-Step Deployment

### 1. Create npm Account (if needed)
```bash
# Sign up at https://www.npmjs.com/signup
# Or create account via CLI
npm adduser
```

### 2. Login to npm
```bash
npm login
# Enter your username, password, and email
```

### 3. Verify Package Name Availability
```bash
npm view ai-templates
# If "npm ERR! 404", the name is available
```

### 4. Clean and Build
```bash
# Clean previous builds
rm -rf dist/

# Install dependencies
npm install

# Build the project
npm run build

# Verify build output
ls -la dist/
```

### 5. Test Locally
```bash
# Test the package locally before publishing
npm link

# In another directory, test installation
cd /tmp
mkdir test-ai-templates
cd test-ai-templates
npm link ai-templates

# Test the CLI
ai-templates

# Unlink when done
npm unlink ai-templates
cd -
npm unlink
```

### 6. Update Version (if needed)
```bash
# For patch release (1.0.0 -> 1.0.1)
npm version patch

# For minor release (1.0.0 -> 1.1.0)
npm version minor

# For major release (1.0.0 -> 2.0.0)
npm version major
```

### 7. Final Package Check
```bash
# See what will be published
npm pack --dry-run

# Check package size
npm pack
ls -lh *.tgz
rm *.tgz
```

### 8. Add .npmignore
Create `.npmignore` to exclude unnecessary files:
```
# .npmignore
src/
.github/
*.log
.env*
.git*
tsconfig.json
test-*
*.test.*
coverage/
.vscode/
.idea/
```

### 9. Publish to npm
```bash
# Publish publicly
npm publish --access public

# Or if scoped package
npm publish --access public --scope=@yourusername
```

### 10. Verify Publication
```bash
# Check on npm
npm view ai-templates

# Visit https://www.npmjs.com/package/ai-templates
```

## 🔄 Post-Publication

### Test Installation
```bash
# Test global installation
npm install -g ai-templates

# Run the CLI
ai-templates

# Check version
ai-templates --version
```

### Update GitHub
1. Create a new release on GitHub
2. Tag the version: `git tag v1.0.0`
3. Push tags: `git push --tags`

## 📝 Publishing Updates

For future updates:
```bash
# 1. Make your changes
# 2. Update version
npm version patch

# 3. Build
npm run build

# 4. Publish
npm publish

# 5. Push to GitHub
git push && git push --tags
```

## 🚨 Troubleshooting

### Common Issues

1. **Name already taken**
   - Choose a different name in package.json
   - Consider scoped package: `@yourusername/ai-templates`

2. **Authentication failed**
   ```bash
   npm logout
   npm login
   ```

3. **Missing files in published package**
   - Check .npmignore
   - Use `files` field in package.json:
   ```json
   "files": [
     "dist/",
     "templates/",
     "README.md",
     "LICENSE"
   ]
   ```

4. **Build errors**
   ```bash
   # Clear node_modules and reinstall
   rm -rf node_modules package-lock.json
   npm install
   npm run build
   ```

## 🔐 Security Best Practices

1. **Enable 2FA on npm account**
   ```bash
   npm profile enable-2fa auth-and-writes
   ```

2. **Use npm access tokens for CI/CD**
   ```bash
   npm token create --read-only
   ```

3. **Review package contents before publishing**
   ```bash
   npm pack
   tar -tzf ai-templates-*.tgz
   ```

## 📊 Package Maintenance

### Monitor Usage
- Check weekly downloads: https://www.npmjs.com/package/ai-templates
- Monitor issues on GitHub
- Respond to user feedback

### Deprecation (if needed)
```bash
npm deprecate ai-templates@"< 1.0.0" "Please upgrade to v1.0.0"
```

### Unpublish (within 72 hours)
```bash
npm unpublish ai-templates@1.0.0
```

## 🎉 Congratulations!

Your package is now available on npm! Users can install it with:
```bash
npm install -g ai-templates
```

Remember to:
- Monitor GitHub issues
- Respond to user feedback within 24 hours (as promised!)
- Keep documentation updated
- Release updates regularly