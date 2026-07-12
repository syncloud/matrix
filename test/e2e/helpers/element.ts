import { Page, expect } from '@playwright/test'

const dismissSelectors = [
  ".mx_Toast_toast button:has-text('Dismiss')",
  ".mx_Toast_toast button:has-text('OK')",
  "button:has-text('Yes, dismiss')",
  ".mx_Dialog button:has-text('Ok')",
]

export async function dismissOverlays(page: Page) {
  for (let i = 0; i < 8; i++) {
    let clicked = false
    for (const selector of dismissSelectors) {
      const button = page.locator(selector).first()
      if (await button.isVisible().catch(() => false)) {
        await button.click().catch(() => {})
        await page.waitForTimeout(500)
        clicked = true
        break
      }
    }
    if (!clicked) break
  }
}

export async function login(page: Page, user: string, password: string) {
  await page.getByRole('link', { name: 'Sign in' }).click()
  await page.locator('#mx_LoginForm_username').fill(user)
  const password_field = page.locator('#mx_LoginForm_password')
  await password_field.fill(password)
  await password_field.press('Enter')
  await expect(page.getByRole('heading', { name: /Welcome user/ })).toBeVisible({ timeout: 60_000 })
  await dismissOverlays(page)
}

export async function composeMenu(page: Page, item: string) {
  await dismissOverlays(page)
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
  await dismissOverlays(page)
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
  await dismissOverlays(page)
  const box = composer(page)
  await box.fill('help')
  await box.press('Enter')
  const botJoined = page
    .locator('.mx_EventTile, .mx_GenericEventListSummary')
    .filter({ hasText: /joined/i })
    .filter({ hasText: /bot/i })
  await expect(botJoined.first()).toBeVisible({ timeout: 60_000 })
  await box.fill('help')
  await box.press('Enter')
  await expect(page.getByRole('heading', { name: 'Administration', exact: true })).toBeVisible({ timeout: 30_000 })
}
