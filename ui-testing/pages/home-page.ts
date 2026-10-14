import { type Locator, type Page } from '@playwright/test';

export type RoomCard = {
  roomId: number;
  type: string;
  price: number;
  features: string[];
};

export class HomePage {
  readonly page: Page;
  readonly contactHeading: Locator;
  readonly contactName: Locator;
  readonly contactEmail: Locator;
  readonly contactPhone: Locator;
  readonly contactSubject: Locator;
  readonly contactMessage: Locator;
  readonly contactSubmit: Locator;
  readonly roomCards: Locator;

  constructor(page: Page) {
    this.page = page;
    this.contactHeading = page.getByRole('heading', { name: 'Send Us a Message' });
    this.contactName = page.getByLabel('Name', { exact: true });
    this.contactEmail = page.getByLabel('Email', { exact: true });
    this.contactPhone = page.getByLabel('Phone', { exact: true });
    this.contactSubject = page.getByLabel('Subject', { exact: true });
    // The Message label points at a non-existent id (known bug), so the textarea has no accessible name.
    this.contactMessage = page.getByTestId('ContactDescription');
    this.contactSubmit = page.getByRole('button', { name: 'Submit' });
    // Room cards have no ARIA role; .room-card is the only container hook. Everything inside uses roles.
    this.roomCards = page.locator('.room-card');
  }

  async goto() {
    await this.page.goto('/');
  }

  bookNowLink(card: Locator): Locator {
    // exact: the hero banner also has a "Book Now" link
    return card.getByRole('link', { name: 'Book now', exact: true });
  }

  // Rooms are fetched after the page loads, and locator.all() does not wait, so wait for the first card.
  async waitForRooms() {
    await this.roomCards.first().waitFor();
  }

  async readRoomCards(): Promise<RoomCard[]> {
    await this.waitForRooms();
    const rooms: RoomCard[] = [];
    for (const card of await this.roomCards.all()) {
      const href = await this.bookNowLink(card).getAttribute('href');
      const footer = await card.getByText(/£\d+/).textContent();
      const badges = await card.locator('.badge').allTextContents();
      rooms.push({
        roomId: Number(href?.match(/\/reservation\/(\d+)/)?.[1]),
        type: (await card.getByRole('heading').textContent())!.trim(),
        price: Number(footer?.match(/£(\d+)/)?.[1]),
        features: badges.map((badge) => badge.trim()),
      });
    }
    return rooms;
  }
}
