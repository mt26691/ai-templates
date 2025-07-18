# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a CLI tool for generating AI-specific configuration files for different frameworks. It creates templates for Cursor, Claude, and Gemini AI tools across backend, frontend, and infrastructure categories.

## Common Commands

### Development
- `npm run dev` - Run the CLI directly with ts-node for development
- `npm run build` - Compile TypeScript to JavaScript
- `npm start` - Build and run the compiled CLI
- `node dist/cli.js` or `ai-templates` (if installed globally) - Run the CLI

### Testing
- `node test-cli.js` - Run the manual integration test

Note: No automated test framework is currently implemented. The test script in package.json is not configured.

### Installation
- `npm install` - Install dependencies
- `npm run build` - Required before running the compiled version

## Architecture Overview

### Core Structure
The application follows an object-oriented design with a single main class:
- `TemplateGenerator` (src/index.ts) - Handles all template generation logic
- `cli.ts` - Entry point with shebang for executable

### Template Organization
Templates are organized in a hierarchical structure:
```
/templates/{ai-tool}/{category}/{framework}/
```
Where:
- AI tools: cursor, claude, gemini
- Categories: backend, frontend, infrastructure
- Frameworks: Various per category (e.g., fastify, nestjs, express for backend)

### Key Features
1. **Interactive CLI**: Uses inquirer for user prompts
2. **Template Migration**: Automatically migrates old `.cursorrules` to `.cursor/rules/`
3. **Template Copying**: Copies entire template directories to target location
4. **Color Output**: Uses chalk for styled terminal output

### TypeScript Configuration
- Strict mode enabled
- Target: ES2020
- Module: CommonJS
- Source maps and declarations generated
- Path aliases configured (@/* -> src/*)

## Important Implementation Details

1. **Template Detection**: The generator checks for existing templates before proceeding
2. **File Operations**: Uses fs-extra for enhanced file system operations
3. **Error Handling**: Basic try-catch blocks around file operations
4. **No Linting Tools**: Project doesn't have ESLint or Prettier configured
5. **Manual Testing Only**: Use test-cli.js for integration testing

## Development Guidelines

When adding new features or templates:
1. Follow the existing template directory structure
2. Maintain the interactive CLI flow pattern
3. Use TypeScript strict mode compliance
4. Follow the coding standards in .cursor/rules/typescript.mdc
5. Test manually using the test-cli.js script