#!/usr/bin/env node

import { runCLI } from './index';

runCLI().catch((error: Error) => {
  console.error('Error:', error.message);
  process.exit(1);
});
