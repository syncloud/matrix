import { test, expect } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import * as oidc from '../helpers/oidc'

const user = process.env.PLAYWRIGHT_DEVICE_USER!
const password = process.env.PLAYWRIGHT_DEVICE_PASSWORD!
const appDomain = process.env.PLAYWRIGHT_APP_DOMAIN!

test('element x next-gen auth through authelia', async ({ page, request }, testInfo) => {
  const client = await oidc.registerClient(request)
  const { verifier, challenge } = oidc.pkce()

  const code = await oidc.authorize(page, client, challenge, user, password)
  await shoot(page, testInfo, 'oidc-native-approved')

  const tokens = await oidc.exchange(request, client, code, verifier)
  expect(tokens.refresh_token).toBeTruthy()

  const me = await oidc.whoami(request, tokens.access_token)
  expect(me.user_id).toBe(`@${user}:${appDomain}`)
  expect(me.device_id).toBe('ELEMENTXTEST')

  const refreshed = await oidc.refresh(request, client, tokens.refresh_token)
  const again = await oidc.whoami(request, refreshed.access_token)
  expect(again.user_id).toBe(`@${user}:${appDomain}`)
})
