import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',
  use: {
    baseURL: 'https://automationintesting.online',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  reporter: [
    ['html', { open: 'never' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['list'],
  ],
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
