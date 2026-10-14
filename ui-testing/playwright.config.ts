import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',
  use: {
    baseURL: 'https://automationintesting.online',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
