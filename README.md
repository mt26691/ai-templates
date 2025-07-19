# AI Templates CLI

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![Open Source](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

**An open-source TypeScript command-line tool for generating AI-specific templates for different frameworks and technologies.** This tool helps developers quickly set up configuration files and guidelines for popular AI tools like Cursor, Claude, and Gemini.

## Features

- 🚀 Interactive CLI with guided selection
- 🎯 Support for multiple AI tools (Cursor, Claude, Gemini)
- 📦 Multiple categories (Backend, Frontend, Infrastructure)
- 🔧 Framework-specific templates
- 📋 Ready-to-use configuration files
- 🎨 Colorful and intuitive interface

## Quick Setup

### Prerequisites

- Node.js 18.0.0 or higher
- npm, yarn, or pnpm

### Installation

#### Option 1: From npm (when published)

```bash
npm install -g ai-templates-cli
```

## Usage

```bash
# Run the CLI tool
ai-templates
```

The tool guides you through 3 simple steps:

1. **Select AI Tool** - Cursor, Claude.
2. **Select Category** - Backend, Frontent.
3. **Select Framework** - Framework-specific templates

## Supported Templates

### Cursor (.cursor/rules/\*.mdc)

- **Backend**: Fastify, NestJS, Koa, Express, Hapi
- **Frontend**: React, Vue, Angular, Svelte, Next.js

### Claude (project_knowledge.md)

- **Backend**: Fastify, NestJS, Koa, Express, Hapi
- **Frontend**: React, Vue, Angular, Svelte, Next.js

## Examples

### Example 1: Generate Cursor rules for React

```bash
$ ai-templates
🚀 AI Templates Generator
Generate templates for your favorite AI tools

? Please select the AI you want to use: Cursor
? Please select the category: Frontend
? Please select the frontend framework: React

🔧 Generating cursor template for react...
✅ Successfully generated cursor template for react!
📁 Files created in: ./.cursor
```

### Example 2: Generate Claude template for Fastify

```bash
$ ai-templates
🚀 AI Templates Generator
Generate templates for your favorite AI tools

? Please select the AI you want to use: Claude
? Please select the category: Backend
? Please select the backend framework: Fastify

🔧 Generating claude template for fastify...
✅ Successfully generated claude template for fastify!
📁 Files created in: ./.claude
```

## Output Structure

The generated templates will be created in a directory named after the selected AI tool:

```
your-project/
├── .cursor/          # Cursor templates
│   └── rules/
│       └── rules.mdc
├── .claude/          # Claude templates
│   └── project_knowledge.md
└── .gemini/          # Gemini templates
    └── ...
```

## Template Contents

### Cursor Templates

- Comprehensive development rules and guidelines
- Code style and best practices
- Example code patterns
- Recommended dependencies
- Testing strategies
- Performance optimization tips

### Claude Templates

- Project knowledge documentation
- Architecture patterns
- Common development patterns
- Key dependencies and tools
- Development guidelines
- Security considerations

## Development

### Project Structure

```
ai-templates-cli/
├── src/
│   ├── cli.ts              # CLI entry point
│   └── index.ts            # Main application logic
├── dist/                   # Compiled TypeScript files
│   ├── cli.js
│   └── index.js
├── templates/              # Template files
│   ├── cursor/
│   │   ├── backend/
│   │   │   ├── fastify/
│   │   │   └── nestjs/
│   │   └── frontend/
│   │       └── react/
│   ├── claude/
│   └── gemini/
├── tsconfig.json           # TypeScript configuration
└── package.json
```

### Development Scripts

```bash
npm run build        # Compile TypeScript
npm run dev          # Run in development mode with ts-node
npm start           # Build and run
npm test            # Run tests
```

### Adding New Templates

1. Create a new directory under `templates/{ai}/{category}/{framework}/`
2. Add your template files
3. Update the `FRAMEWORK_OPTIONS` in `src/index.ts` if needed
4. Run `npm run build` to compile TypeScript changes

## 🤝 Contributing

We welcome contributions from the community! This is an open-source project and we're committed to making it better with your help.

### How to Contribute

#### Option 1: Submit a Pull Request (Recommended)

#### Option 2: Create an Issue

If you're not comfortable with creating a pull request or want to discuss an idea first:

1. **Open an Issue** on our [GitHub Issues](https://github.com/mt26691/ai-templates-cli/issues)
2. Use the appropriate issue template:
   - 🐛 Bug Report
   - ✨ Feature Request
   - 📚 Documentation Update
   - 💡 General Idea/Discussion

### 🚀 Our Commitment

**We are committed to responding to all issues within 24 hours!**

- ✅ Issue acknowledgment within 24 hours
- ✅ We'll work on accepted issues promptly
- ✅ Regular updates on progress
- ✅ Clear communication throughout the process

### Contribution Guidelines

- **Code Style**: Follow the existing code style (TypeScript, ESLint rules)
- **Templates**: Ensure templates are well-documented and follow best practices
- **Testing**: Add tests for new functionality when applicable
- **Documentation**: Update README.md if you're adding new features

## 📬 Support

- **Issues**: [GitHub Issues](https://github.com/mt26691/ai-templates-cli/issues)
- **Discussions**: [GitHub Discussions](https://github.com/mt26691/ai-templates-cli/discussions)

### Priority Support

- 🔴 **Critical Bugs**: Fixed within 24 hours
- 🟡 **Feature Requests**: Reviewed within 24 hours
- 🟢 **Enhancements**: Implemented based on community interest

## 🙏 Acknowledgments

Thanks to all our contributors! This project exists because of your support.

<!-- ALL-CONTRIBUTORS-LIST:START -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. This means you can freely use, modify, distribute, and sell this software.

## Changelog

### v1.0.0

- Initial release
- Support for Cursor, Claude, and Gemini
- Backend, Frontend, and Infrastructure templates
- Interactive CLI interface
- Framework-specific templates for popular tools
