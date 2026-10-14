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

  test('every listed room type has a "Book now" link to that room', async ({ request }) => {
    const response = await request.get('/api/room');
    await expect(response).toBeOK();
    const { rooms } = await response.json();
  
    // Same number of cards as rooms, and each room has a card linking to it, so no room is missing or extra.
    await expect(homePage.roomCards).toHaveCount(rooms.length);
  
    for (const room of rooms) {
      const card = homePage.roomCard(room.roomid);
      await expect(card.getByRole('heading')).toHaveText(room.type);
      await expect(homePage.bookNowLink(card)).toBeVisible();
    }
  });
  
  test('Message field has an accessible label', { tag: '@knownbug' }, async ({ page }) => {
    test.fail(true, 'The Message label targets id "message" but the textarea has id "description"');
    await expect(page.getByLabel('Message', { exact: true })).toBeVisible({ timeout: 2000 });
  });
  test('room images describe their own room type', { tag: '@knownbug' }, async () => {
    test.fail(true, 'Every room image has the alt text "Single Room", whatever the room type');
    await homePage.waitForRooms();
    for (const card of await homePage.roomCards.all()) {
      const type = await card.getByRole('heading').textContent();
      await expect(card.getByRole('img')).toHaveAttribute('alt', `${type} Room`, { timeout: 2000 });
    }
  });
})

