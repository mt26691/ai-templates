#!/usr/bin/env node

const { spawn } = require('child_process');
const fs = require('fs-extra');
const path = require('path');

async function testCLI() {
  console.log('🧪 Testing AI Templates CLI...\n');

  // Test 1: Generate Cursor template for Fastify
  console.log('Test 1: Generating Cursor template for Fastify...');

  const testDir = path.join(__dirname, 'test-output');
  await fs.ensureDir(testDir);

  const cli = spawn('node', [path.join(__dirname, 'dist/cli.js')], {
    cwd: testDir,
    stdio: ['pipe', 'pipe', 'pipe'],
  });

  // Simulate user input
  cli.stdin.write('\n'); // Select Cursor (default)
  cli.stdin.write('\n'); // Select Backend (default)
  cli.stdin.write('\n'); // Select Fastify (default)
  cli.stdin.end();

  let output = '';
  cli.stdout.on('data', (data) => {
    output += data.toString();
  });

  cli.stderr.on('data', (data) => {
    console.error('Error:', data.toString());
  });

  cli.on('close', async (code) => {
    console.log('CLI output:');
    console.log(output);

    // Check if the template was generated
    const cursorDir = path.join(testDir, '.cursor');
    const rulesDir = path.join(cursorDir, 'rules');

    let mdcFiles = [];
    if (await fs.pathExists(rulesDir)) {
      mdcFiles = await fs.readdir(rulesDir);
    }

    const mdcFile = mdcFiles.find((file) => file.endsWith('.mdc'));

    if (mdcFile) {
      console.log('✅ Test 1 PASSED: Cursor template generated successfully');
      const content = await fs.readFile(path.join(rulesDir, mdcFile), 'utf8');
      console.log(
        `📄 Template content preview: ${content.substring(0, 100)}...`
      );
    } else {
      console.log('❌ Test 1 FAILED: Cursor template not generated');
    }

    // Cleanup
    await fs.remove(testDir);
    console.log('\n🧹 Cleanup completed');
  });
}

// Run the test
testCLI().catch(console.error);
