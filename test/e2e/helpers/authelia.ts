import { Page, expect } from '@playwright/test'

export async function signIn(page: Page, user: string, password: string) {
  const username = page.locator('#username-textfield')
  await expect(username).toBeVisible({ timeout: 60_000 })
  await username.fill(user)
  await page.locator('#password-textfield').fill(password)
  await page.locator('#sign-in-button').click()
  const consent = page.locator('#openid-consent-accept')
  if (await consent.waitFor({ state: 'visible', timeout: 5_000 }).then(() => true).catch(() => false)) {
    await consent.click()
  }
}

export async function approve(page: Page) {
  const button = page.getByRole('button', { name: 'Approve', exact: true })
  await expect(button).toBeVisible({ timeout: 60_000 })
  await button.click()
}

export async function approveIfAsked(page: Page) {
  const button = page.getByRole('button', { name: 'Approve', exact: true })
  if (await button.waitFor({ state: 'visible', timeout: 20_000 }).then(() => true).catch(() => false)) {
    await button.click()
  }
}
