import { test, expect } from '@playwright/test';
import { AdminLoginPage } from '../pages/admin-login-page';
import { AdminPanelPage } from '../pages/admin-panel-page';

// These tests exercise the login itself, so they start signed out.
test.use({ storageState: { cookies: [], origins: [] } });

const adminUser = 'admin';
const adminPassword = 'password';

test.describe('Admin authentication', () => {
  let loginPage: AdminLoginPage;
  let adminPanel: AdminPanelPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new AdminLoginPage(page);
    adminPanel = new AdminPanelPage(page);
    await loginPage.goto();
  });

  test('admin logs in and is redirected to the admin dashboard', async ({ page }) => {
    await loginPage.login(adminUser, adminPassword);

    // The brief expects a "Dashboard/Inboxes" view; the app lands on the Rooms tab of the admin panel.
    await expect(page).toHaveURL("https://automationintesting.online/admin");
    await expect(adminPanel.roomsTab).toBeVisible();
    await expect(adminPanel.reportTab).toBeVisible();
    await expect(adminPanel.brandingTab).toBeVisible();
    await expect(adminPanel.messagesTab).toBeVisible();
    await expect(adminPanel.logoutButton).toBeVisible();
    await expect(loginPage.heading).toBeHidden();

    const cookies = await page.context().cookies();
    expect(cookies.find((cookie) => cookie.name === 'token')?.value).toBeTruthy();
  });

  test('wrong password is rejected and stays on the login page', async ({ page }) => {
    await loginPage.login(adminUser, 'not-the-password');

    await expect(loginPage.errorAlert).toBeVisible();
    await expect(page).toHaveURL(/\/admin$/);
    await expect(adminPanel.roomsTab).toBeHidden();
  });

  test('logout ends the session', async ({ page }) => {
    await loginPage.login(adminUser, adminPassword);
    await expect(adminPanel.roomsTab).toBeVisible();

    await adminPanel.logoutButton.click();
    await expect(page).toHaveURL('/');

    // The admin area must not be reachable after logout.
    await adminPanel.goto();
    await expect(loginPage.heading).toBeVisible();
    await expect(adminPanel.roomsTab).toBeHidden();
  });

  test('Logout button is hidden before logging in', { tag: '@knownbug' }, async () => {
    test.fail(true, 'The login page shows a Logout button to signed-out visitors');
    await expect(adminPanel.logoutButton).toBeHidden({ timeout: 2000 });
  });
});
