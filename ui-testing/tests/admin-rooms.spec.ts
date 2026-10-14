import { test, expect } from '@playwright/test';
import { HomePage } from '../pages/home-page';
import { AdminLoginPage } from '../pages/admin-login-page';
import { AdminPanelPage } from '../pages/admin-panel-page';


const adminUser = 'admin';
const adminPassword = 'password';

test.describe('Admin rooms', () => {
  let loginPage: AdminLoginPage;
  let adminPanel: AdminPanelPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new AdminLoginPage(page);
    adminPanel = new AdminPanelPage(page);
    await loginPage.goto();
    await loginPage.login(adminUser, adminPassword);
    await expect(adminPanel.roomsTab).toBeVisible();  
  });


  test('rooms in the admin panel match the public homepage', async ({ page }) => {
    const homePage = new HomePage(page);
    await homePage.goto();
    const publicRooms = await homePage.readRoomCards();
    expect(publicRooms.length).toBeGreaterThan(0);

    const adminPanel = new AdminPanelPage(page);
    await adminPanel.goto();
    await adminPanel.roomsTab.click();
    await expect(adminPanel.roomRows.first()).toBeVisible();

    // Without its roomId, a public room has the same fields as an admin row: type, price, features.
    for (const { roomId, ...publicRoom } of publicRooms) {
      await test.step(`${publicRoom.type} room (id ${roomId})`, async () => {
        await expect(adminPanel.roomRow(roomId)).toBeVisible();
        expect(await adminPanel.readRoomRow(roomId)).toEqual(publicRoom);
      });
    }
  });
});
