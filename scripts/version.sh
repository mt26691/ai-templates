#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📝 Version Bump Script${NC}"
echo ""

# Get current version
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo -e "${BLUE}Current version: ${CURRENT_VERSION}${NC}"
echo ""

# Check for command line argument
if [ "$1" == "patch" ] || [ "$1" == "minor" ] || [ "$1" == "major" ]; then
    VERSION_TYPE=$1
else
    # Ask for version bump
    echo -e "${YELLOW}How would you like to bump the version?${NC}"
    echo "1) Patch (1.0.0 → 1.0.1) - Bug fixes"
    echo "2) Minor (1.0.0 → 1.1.0) - New features"
    echo "3) Major (1.0.0 → 2.0.0) - Breaking changes"
    echo ""
    read -p "Select option (1-3): " version_choice

    case $version_choice in
        1) VERSION_TYPE="patch" ;;
        2) VERSION_TYPE="minor" ;;
        3) VERSION_TYPE="major" ;;
        *)
            echo -e "${RED}Invalid option. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

# Bump version
echo -e "${YELLOW}Bumping ${VERSION_TYPE} version...${NC}"
npm version $VERSION_TYPE --no-git-tag-version

# Get new version
NEW_VERSION=$(node -p "require('./package.json').version")
echo -e "${GREEN}✅ Version bumped to ${NEW_VERSION}${NC}"

# Create git commit
echo ""
read -p "Create git commit? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add package.json package-lock.json
    git commit -m "chore: bump version to ${NEW_VERSION}"
    git tag "v${NEW_VERSION}"
    echo -e "${GREEN}✅ Created commit and tag v${NEW_VERSION}${NC}"
    echo -e "${BLUE}To push: git push origin main --tags${NC}"
fi