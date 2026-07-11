import { test } from '@playwright/test'
import * as path from 'node:path'
import { fileURLToPath } from 'node:url'
import { shoot } from '../helpers/screenshot'
import * as el from '../helpers/element'

const here = path.dirname(fileURLToPath(import.meta.url))
const user = process.env.PLAYWRIGHT_DEVICE_USER ?? 'user'
const password = process.env.PLAYWRIGHT_DEVICE_PASSWORD ?? 'Password1'
const appDomain = process.env.PLAYWRIGHT_APP_DOMAIN ?? 'matrix.bookworm.com'
const bridges = ['whatsapp', 'telegram', 'signal', 'slack', 'discord']

test('matrix element-web ui', async ({ page }, testInfo) => {
  await el.registerDismissers(page)
  await page.goto('/')
  await shoot(page, testInfo, 'welcome')

  await el.login(page, user, password)
  await shoot(page, testInfo, 'main')

  await el.createRoom(page, 'testroom')
  await shoot(page, testInfo, 'room')

  await el.openRoom(page, 'testroom')
  await el.sendMessage(page, 'test message')
  await shoot(page, testInfo, 'message')

  await el.uploadFile(page, path.join(here, '..', '..', 'images', 'profile.jpeg'))
  await shoot(page, testInfo, 'image')

  for (const bridge of bridges) {
    await el.bridgeBot(page, bridge, appDomain)
    await shoot(page, testInfo, `${bridge}-bot`)
  }
})
