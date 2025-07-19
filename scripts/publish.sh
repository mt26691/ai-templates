#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
else
    echo -e "${RED}❌ Publishing failed${NC}"
    exit 1
fi