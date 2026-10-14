import { test, expect } from '@playwright/test';

test('contact form is visible on the homepage', async ({ page }) => {
  await page.goto('/#contact');
  await expect(page.getByTestId('ContactName')).toBeVisible();
  await expect(page.getByTestId('ContactEmail')).toBeVisible();
  await expect(page.getByTestId('ContactPhone')).toBeVisible();
  await expect(page.getByTestId('ContactSubject')).toBeVisible();
  await expect(page.getByTestId('ContactDescription')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Submit' })).toBeVisible();
});

test('a Book now button is present for each listed room', async ({ page }) => {
  await page.goto('/');
  // index 0 is the hero banner CTA; each of the 3 room cards has its own "Book now".
  await expect(page.locator('.room-card').getByRole('link', { name: 'Book now' })).toHaveCount(3);
});