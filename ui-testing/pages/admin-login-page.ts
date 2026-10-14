import { type Locator, type Page } from '@playwright/test';

export class AdminLoginPage {
  readonly page: Page;
  readonly heading: Locator;
  readonly username: Locator;
  readonly password: Locator;
  readonly loginButton: Locator;
  readonly errorAlert: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: 'Login' });
    this.username = page.getByLabel('Username');
    this.password = page.getByLabel('Password');
    this.loginButton = page.getByRole('button', { name: 'Login' });
    this.errorAlert = page.getByRole('alert').filter({ hasText: 'Invalid credentials' });
  }

  async goto() {
    await this.page.goto('/admin');
  }

  async login(username: string, password: string) {
    await this.username.fill(username);
    await this.password.fill(password);
    await this.loginButton.click();
  }
}
