#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 AI Templates - npm Publishing Script${NC}"
echo ""

# Check if logged in to npm
echo -e "${YELLOW}Checking npm login status...${NC}"
npm whoami &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Not logged in to npm. Please run: npm login${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Logged in to npm${NC}"

# Get current version
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo -e "${BLUE}Current version: ${CURRENT_VERSION}${NC}"
echo ""

# Ask for version bump
echo -e "${YELLOW}How would you like to bump the version?${NC}"
echo "1) Patch (1.0.0 → 1.0.1) - Bug fixes"
echo "2) Minor (1.0.0 → 1.1.0) - New features"
echo "3) Major (1.0.0 → 2.0.0) - Breaking changes"
echo "4) Skip version bump"
echo ""
read -p "Select option (1-4): " version_choice

case $version_choice in
    1)
        echo -e "${YELLOW}Bumping patch version...${NC}"
        npm version patch --no-git-tag-version
        ;;
    2)
        echo -e "${YELLOW}Bumping minor version...${NC}"
        npm version minor --no-git-tag-version
        ;;
    3)
        echo -e "${YELLOW}Bumping major version...${NC}"
        npm version major --no-git-tag-version
        ;;
    4)
        echo -e "${YELLOW}Skipping version bump...${NC}"
        ;;
    *)
        echo -e "${RED}Invalid option. Exiting.${NC}"
        exit 1
        ;;
esac

# Get new version
NEW_VERSION=$(node -p "require('./package.json').version")
if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
    echo -e "${GREEN}✅ Version bumped to ${NEW_VERSION}${NC}"
else
    echo -e "${BLUE}Version remains ${CURRENT_VERSION}${NC}"
fi
echo ""

# Clean and build
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf dist/
echo -e "${GREEN}✅ Cleaned dist directory${NC}"

echo -e "${YELLOW}Installing dependencies...${NC}"
npm install
echo -e "${GREEN}✅ Dependencies installed${NC}"

echo -e "${YELLOW}Building project...${NC}"
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build successful${NC}"

# Check what will be published
echo -e "${YELLOW}Files to be published:${NC}"
npm pack --dry-run

# Ask for confirmation
echo ""
read -p "Do you want to publish to npm? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Publishing cancelled${NC}"
    exit 1
fi

# Publish
echo -e "${YELLOW}Publishing to npm...${NC}"
npm publish --access public
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully published to npm!${NC}"
    echo -e "${GREEN}📦 Package available at: https://www.npmjs.com/package/ai-templates${NC}"
    
    # Git operations
    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
        echo ""
        echo -e "${YELLOW}Creating git commit and tag...${NC}"
        git add package.json package-lock.json
        git commit -m "chore: bump version to ${NEW_VERSION}"
        git tag "v${NEW_VERSION}"
        echo -e "${GREEN}✅ Created git tag v${NEW_VERSION}${NC}"
        
        echo ""
        read -p "Push changes to GitHub? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push origin main
            git push origin "v${NEW_VERSION}"
            echo -e "${GREEN}✅ Pushed to GitHub${NC}"
            echo -e "${BLUE}Create release at: https://github.com/mt26691/ai-templates/releases/new?tag=v${NEW_VERSION}${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Publishing failed${NC}"
    # Revert version bump if publish failed
    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
        echo -e "${YELLOW}Reverting version bump...${NC}"
        npm version "$CURRENT_VERSION" --no-git-tag-version --force
    fi
    exit 1
fi