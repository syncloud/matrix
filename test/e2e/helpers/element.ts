import { Page, expect } from '@playwright/test'

// element-web 1.12 shows transient overlays (unsupported-browser toast,
// key-storage nag) whose backdrops intercept clicks. Auto-dismiss them
// whenever they block an action.
export async function registerDismissers(page: Page) {
  await page.addLocatorHandler(
    page.getByRole('button', { name: 'Yes, dismiss' }),
    async (locator) => { await locator.click() },
  )
  await page.addLocatorHandler(
    page.locator('.mx_Toast_toast').getByRole('button', { name: 'Dismiss' }),
    async (locator) => { await locator.click() },
  )
}

export async function login(page: Page, user: string, password: string) {
  await page.getByRole('link', { name: 'Sign in' }).click()
  await page.locator('#mx_LoginForm_username').fill(user)
  const password_field = page.locator('#mx_LoginForm_password')
  await password_field.fill(password)
  await password_field.press('Enter')
  await expect(page.getByRole('heading', { name: /Welcome user/ })).toBeVisible({ timeout: 60_000 })
}

// The compose button opens a Radix menu; a one-time "Introducing Sections"
// announcement can cover the top item. Retry open + dismiss until the item
// is clickable.
export async function composeMenu(page: Page, item: string) {
  const compose = page.getByRole('button', { name: 'New conversation', exact: true })
  const menuItem = page.getByRole('menuitem', { name: item, exact: true })
  const ok = page.getByRole('dialog').getByRole('button', { name: 'Ok', exact: true })
  await expect(async () => {
    if (!(await menuItem.isVisible())) {
      await compose.click()
    }
    if (await ok.isVisible()) {
      await ok.click()
    }
    await menuItem.click({ timeout: 3_000 })
  }).toPass({ timeout: 30_000 })
}

export async function createRoom(page: Page, name: string) {
  await composeMenu(page, 'New room')
  await page.getByRole('textbox', { name: 'Name' }).fill(name)
  await page.getByRole('button', { name: 'Create room' }).click()
}

export async function openRoom(page: Page, name: string) {
  await page.getByTestId('room-list').locator(`[title="${name}"]`).first().click()
}

function composer(page: Page) {
  return page.getByRole('region', { name: 'Message composer' }).getByRole('textbox')
}

export async function sendMessage(page: Page, text: string) {
  const box = composer(page)
  await box.fill(text)
  await box.press('Enter')
}

export async function uploadFile(page: Page, filePath: string) {
  await page.locator('input[type="file"][multiple]').setInputFiles(filePath)
  await page.getByRole('dialog').getByRole('button', { name: 'Upload' }).click()
  await expect(page.getByRole('heading', { name: 'Upload Failed' })).toHaveCount(0)
}

export async function bridgeBot(page: Page, bridge: string, appDomain: string) {
  const botId = `@${bridge}bot:${appDomain}`
  await composeMenu(page, 'Start chat')
  const dialog = page.getByRole('dialog', { name: 'Direct Messages' })
  const input = dialog.locator('input').first()
  await input.fill(botId)
  await input.press('Enter')
  await dialog.locator('.mx_InviteDialog_goButton').click()
  for (const label of ['Continue', 'Yes']) {
    const button = page.getByRole('button', { name: label, exact: true })
    if (await button.isVisible().catch(() => false)) {
      await button.click()
    }
  }
  // Re-send help until the bot answers with its Administration help section.
  await expect(async () => {
    const box = composer(page)
    await box.fill('help')
    await box.press('Enter')
    await expect(page.getByRole('heading', { name: 'Administration', exact: true })).toBeVisible({ timeout: 15_000 })
  }).toPass({ timeout: 150_000 })
}
