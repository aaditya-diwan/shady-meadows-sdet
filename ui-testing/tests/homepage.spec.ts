import { test, expect } from '@playwright/test';

test('contact form is visible', async ({ page }) => {
  await page.goto('/#contact');
  await page.locator('#navbarNav').getByRole('link', { name: 'Contact' }).click();
  await expect(page.getByText('Name')).toBeVisible();
  await expect(page.getByTestId('ContactName')).toBeVisible();
  await expect(page.locator('#contact').getByText('Email')).toBeVisible();
  await expect(page.getByTestId('ContactEmail')).toBeVisible();
  await expect(page.locator('#contact').getByText('Phone')).toBeVisible();
  await expect(page.getByTestId('ContactPhone')).toBeVisible();
  await expect(page.locator('div').filter({ hasText: /^Subject$/ })).toBeVisible();
  await expect(page.getByTestId('ContactSubject')).toBeVisible();
  await expect(page.getByText('Message', { exact: true })).toBeVisible();
  await expect(page.getByTestId('ContactDescription')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Submit' })).toBeVisible();
});

test('book buttons present for the ', async ({ page }) => {
  await page.goto('/');
  await page.locator('#navbarNav').getByRole('link', { name: 'Rooms' }).click();
  await expect(page.getByRole('link', { name: 'Book now' }).nth(1)).toBeVisible();
  await expect(page.getByRole('link', { name: 'Book now' }).nth(2)).toBeVisible();
  await expect(page.getByRole('link', { name: 'Book now' }).nth(3)).toBeVisible();
});