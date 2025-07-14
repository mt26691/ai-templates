import inquirer from 'inquirer';
import chalk from 'chalk';
import * as fs from 'fs-extra';
import path from 'path';

interface Choice {
  name: string;
  value: string;
}

interface FrameworkOptions {
  [key: string]: Choice[];
}

const AI_OPTIONS: Choice[] = [
  { name: 'Cursor', value: 'cursor' },
  { name: 'Claude', value: 'claude' },
  { name: 'Gemini', value: 'gemini' },
];

const CATEGORY_OPTIONS: Choice[] = [
  { name: 'Backend', value: 'backend' },
  { name: 'Frontend', value: 'frontend' },
  { name: 'Infrastructure', value: 'infra' },
];

const FRAMEWORK_OPTIONS: FrameworkOptions = {
  backend: [
    { name: 'Fastify', value: 'fastify' },
    { name: 'NestJS', value: 'nestjs' },
    { name: 'Koa', value: 'koa' },
    { name: 'Express', value: 'express' },
    { name: 'Hapi', value: 'hapi' },
  ],
  frontend: [
    { name: 'React', value: 'react' },
    { name: 'Vue', value: 'vue' },
    { name: 'Angular', value: 'angular' },
    { name: 'Svelte', value: 'svelte' },
    { name: 'Next.js', value: 'nextjs' },
  ],
  infra: [
    { name: 'Docker', value: 'docker' },
    { name: 'Kubernetes', value: 'kubernetes' },
    { name: 'Terraform', value: 'terraform' },
    { name: 'AWS CDK', value: 'aws-cdk' },
    { name: 'Pulumi', value: 'pulumi' },
  ],
};

export class TemplateGenerator {
  private templatesDir: string;

  constructor() {
    // For development, use relative to source directory
    // For production, use relative to the distributed file
    this.templatesDir = path.join(__dirname, '..', 'templates');
  }

  async selectAI(): Promise<string> {
    console.log(chalk.blue('🚀 AI Templates Generator'));
    console.log(chalk.gray('Generate templates for your favorite AI tools\n'));

    const answers = await inquirer.prompt([
      {
        type: 'list',
        name: 'ai',
        message: 'Please select the AI you want to use:',
        choices: AI_OPTIONS,
      },
    ]);

    return answers.ai;
  }

  async selectCategory(): Promise<string> {
    const answers = await inquirer.prompt([
      {
        type: 'list',
        name: 'category',
        message: 'Please select the category:',
        choices: CATEGORY_OPTIONS,
      },
    ]);

    return answers.category;
  }

  async selectFramework(category: string): Promise<string> {
    const frameworks = FRAMEWORK_OPTIONS[category];

    if (!frameworks) {
      throw new Error(`No frameworks available for category: ${category}`);
    }

    const answers = await inquirer.prompt([
      {
        type: 'list',
        name: 'framework',
        message: `Please select the ${category} framework:`,
        choices: frameworks,
      },
    ]);

    return answers.framework;
  }

  async generateTemplate(
    ai: string,
    category: string,
    framework: string
  ): Promise<void> {
    const templatePath = path.join(this.templatesDir, ai, category, framework);

    if (!(await fs.pathExists(templatePath))) {
      console.log(
        chalk.red(`❌ Template not found for ${ai}/${category}/${framework}`)
      );
      return;
    }

    const outputDir = path.join(process.cwd(), `.${ai}`);
    await fs.ensureDir(outputDir);

    try {
      await fs.copy(templatePath, outputDir);

      // Post-process Cursor templates: migrate .cursorrules to the new .cursor/rules structure
      if (ai === 'cursor') {
        const oldRulesPath = path.join(outputDir, '.cursorrules');
        if (await fs.pathExists(oldRulesPath)) {
          const rulesDir = path.join(outputDir, 'rules');
          await fs.ensureDir(rulesDir);
          const newRulesPath = path.join(rulesDir, 'rules.mdc');
          await fs.move(oldRulesPath, newRulesPath, { overwrite: true });
        }
      }

      console.log(
        chalk.green(
          `✅ Successfully generated ${ai} template for ${framework}!`
        )
      );
      console.log(chalk.gray(`📁 Files created in: ${outputDir}`));
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.log(chalk.red(`❌ Error generating template: ${errorMessage}`));
    }
  }
}

export async function runCLI(): Promise<void> {
  const generator = new TemplateGenerator();

  try {
    const ai = await generator.selectAI();
    const category = await generator.selectCategory();
    const framework = await generator.selectFramework(category);

    console.log(
      chalk.yellow(`\n🔧 Generating ${ai} template for ${framework}...`)
    );

    await generator.generateTemplate(ai, category, framework);
  } catch (error) {
    if (error && typeof error === 'object' && 'isTtyError' in error) {
      console.log(
        chalk.red("❌ Prompt couldn't be rendered in the current environment")
      );
    } else {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.log(chalk.red(`❌ Error: ${errorMessage}`));
    }
  }
}
