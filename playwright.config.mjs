import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './playwright',
  timeout: 60000,
  expect: { timeout: 10000 },
  retries: 1,
  workers: 2,
  use: {
    headless: true,
    viewport: { width: 1280, height: 900 },
    actionTimeout: 8000,
    launchOptions: {
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--ignore-gpu-blocklist',
      ],
    },
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
  reporter: [['list'], ['json', { outputFile: 'playwright/results.json' }]],
});