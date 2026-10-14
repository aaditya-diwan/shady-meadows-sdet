import { test, expect } from '@playwright/test';
import { HomePage } from '../pages/home-page';



test.describe('HomePage', () => {
  let homePage: HomePage
  test.beforeEach(async ({ page }) => {
    homePage = new HomePage(page);
    await homePage.goto();
  });

  test('contact form is visible', async () => {
    await expect(homePage.contactHeading).toBeVisible();
    await expect(homePage.contactName).toBeVisible();
    await expect(homePage.contactEmail).toBeVisible();
    await expect(homePage.contactPhone).toBeVisible();
    await expect(homePage.contactSubject).toBeVisible();
    await expect(homePage.contactMessage).toBeVisible();
    await expect(homePage.contactSubmit).toBeEnabled();
  });

})

