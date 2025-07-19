# AI Templates CLI

A TypeScript command-line tool for generating AI-specific templates for different frameworks and technologies. This tool helps developers quickly set up configuration files and guidelines for popular AI tools like Cursor, Claude, and Gemini.

## Features

- 🚀 Interactive CLI with guided selection
- 🎯 Support for multiple AI tools (Cursor, Claude, Gemini)
- 📦 Multiple categories (Backend, Frontend, Infrastructure)
- 🔧 Framework-specific templates
- 📋 Ready-to-use configuration files
- 🎨 Colorful and intuitive interface

## Quick Setup

### Prerequisites
- Node.js 14.0.0 or higher
- npm, yarn, or pnpm

### Installation

#### Option 1: From npm (when published)
```bash
npm install -g ai-templates-cli
```

#### Option 2: From source
```bash
# Clone the repository
git clone https://github.com/yourusername/ai-templates-cli.git
cd ai-templates-cli

# Install dependencies
npm install

# Build the project
npm run build

# Link globally
npm link
```

## Usage

Run the CLI tool:

```bash
ai-templates
```

Or if running from source:

```bash
npm start
```

The tool will guide you through three simple steps:

1. **Select AI Tool**: Choose from Cursor, Claude, or Gemini
2. **Select Category**: Choose from Backend, Frontend, or Infrastructure
3. **Select Framework**: Choose from available frameworks for your category

## Supported Templates

### Cursor (.cursor/rules/\*.mdc)

- **Backend**: Fastify, NestJS, Koa, Express, Hapi
- **Frontend**: React, Vue, Angular, Svelte, Next.js
- **Infrastructure**: Docker, Kubernetes, Terraform, AWS CDK, Pulumi

### Claude (project_knowledge.md)

- **Backend**: Fastify, NestJS, Koa, Express, Hapi
- **Frontend**: React, Vue, Angular, Svelte, Next.js
- **Infrastructure**: Docker, Kubernetes, Terraform, AWS CDK, Pulumi

### Gemini

- **Backend**: Fastify, NestJS, Koa, Express, Hapi
- **Frontend**: React, Vue, Angular, Svelte, Next.js
- **Infrastructure**: Docker, Kubernetes, Terraform, AWS CDK, Pulumi

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

### Gemini Templates

- Framework-specific configurations
- Development workflows
- Best practices and patterns
- Tool recommendations
- Performance guidelines

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

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add your templates or improvements
4. Submit a pull request

## Requirements

- Node.js 14.0.0 or higher
- npm or yarn
- TypeScript 5.0.0 or higher (for development)

## License

MIT License - see LICENSE file for details

## Support

- Report issues on GitHub
- Feature requests welcome
- Pull requests appreciated

## Changelog

### v1.0.0

- Initial release
- Support for Cursor, Claude, and Gemini
- Backend, Frontend, and Infrastructure templates
- Interactive CLI interface
- Framework-specific templates for popular tools
