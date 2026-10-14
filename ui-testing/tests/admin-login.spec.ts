import { test, expect } from '@playwright/test';

const ADMIN_USER = 'admin';
const ADMIN_PASSWORD = 'password';

test.describe('Admin Authentication & Dashboard', () => {

  test('admin can log in and reach the dashboard', async ({ page }) => {
    await page.goto('/admin'); 

    await page.getByRole('textbox', { name: 'Username' }).fill(ADMIN_USER);
    await page.getByRole('textbox', { name: 'Password' }).fill(ADMIN_PASSWORD);
    await page.getByRole('button', { name: 'Login' }).click();

    await expect(page).toHaveURL(/\/admin\/rooms/);
    await expect(page.getByRole('link', { name: 'Rooms' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'Messages' })).toBeVisible();

    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('bonus: the Single room details match between homepage and admin', async ({ page }) => {
    await page.goto('/');
    const homeSingleCard = page.locator('.room-card').filter({ hasText: 'Single' });
    await expect(homeSingleCard).toBeVisible();
    await expect(homeSingleCard).toContainText('WiFi'); // amenity shown on the card
    await expect(page.getByText('£100')).toBeVisible();  // Single room price on the homepage

    await page.goto('/admin');
    await page.getByRole('textbox', { name: 'Username' }).fill(ADMIN_USER);
    await page.getByRole('textbox', { name: 'Password' }).fill(ADMIN_PASSWORD);
    await page.getByRole('button', { name: 'Login' }).click();
    await page.getByRole('link', { name: 'Rooms' }).click();

    // --- The same Single room in admin shows matching details ---

    const adminSingleRow = page.getByTestId('roomlisting').filter({ hasText: 'Single' });
    await expect(adminSingleRow).toBeVisible();
    await expect(adminSingleRow).toContainText('100');   // price matches the £100 on the homepage
    await expect(adminSingleRow).toContainText('WiFi');  // amenity matches the homepage card
  });
});