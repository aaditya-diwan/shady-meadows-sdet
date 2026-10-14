import { type Locator, type Page } from '@playwright/test';

export type AdminRoomRow = {
  type: string;
  price: number;
  features: string[];
};

// The admin area after login: navigation bar plus the Rooms tab.
export class AdminPanelPage {
  readonly page: Page;
  readonly roomsTab: Locator;
  readonly reportTab: Locator;
  readonly brandingTab: Locator;
  readonly messagesTab: Locator;
  readonly logoutButton: Locator;
  readonly roomRows: Locator;

  constructor(page: Page) {
    this.page = page;
    this.roomsTab = page.getByRole('link', { name: 'Rooms', exact: true });
    this.reportTab = page.getByRole('link', { name: 'Report' });
    this.brandingTab = page.getByRole('link', { name: 'Branding' });
    this.messagesTab = page.getByRole('link', { name: /^Messages/ });
    this.logoutButton = page.getByRole('button', { name: 'Logout' });
    this.roomRows = page.getByTestId('roomlisting');
  }

  async goto() {
    await this.page.goto('/admin/rooms');
  }

  // Rows carry the room id in their element id (room1, room2, ...), the same id the public site uses in its booking links.
  roomRow(roomId: number): Locator {
    return this.roomRows.and(this.page.locator(`#room${roomId}`));
  }

  async readRoomRow(roomId: number): Promise<AdminRoomRow> {
    // allTextContents() does not wait, so wait for the row to render first.
    await this.roomRow(roomId).waitFor();
    const cells = await this.roomRow(roomId).getByRole('paragraph').allTextContents();
    // columns: room number, type, accessible, price, details (features)
    const [, type, , price, features] = cells.map((cell) => cell.trim());
    return {
      type,
      price: Number(price),
      features: features ? features.split(',').map((feature) => feature.trim()) : [],
    };
  }
}
