import { APIRequestContext, Page, expect } from '@playwright/test'
import { createHash, randomBytes } from 'node:crypto'
import * as authelia from './authelia'

export const redirectUri = 'io.element.elementx:/callback'

export interface Client {
  clientId: string
  tokenEndpoint: string
  authorizationEndpoint: string
}

export interface Tokens {
  access_token: string
  refresh_token: string
}

export function pkce() {
  const verifier = randomBytes(48).toString('base64url')
  const challenge = createHash('sha256').update(verifier).digest('base64url')
  return { verifier, challenge }
}

export async function registerClient(request: APIRequestContext): Promise<Client> {
  const metadata = await request.get('/_matrix/client/v1/auth_metadata')
  expect(metadata.status()).toBe(200)
  const meta = await metadata.json()
  const registration = await request.post(meta.registration_endpoint, {
    data: {
      client_name: 'Element X',
      client_uri: 'https://element.io',
      redirect_uris: [redirectUri],
      application_type: 'native',
      token_endpoint_auth_method: 'none',
      grant_types: ['authorization_code', 'refresh_token'],
      response_types: ['code'],
    },
  })
  expect(registration.status()).toBe(201)
  const client = await registration.json()
  return {
    clientId: client.client_id,
    tokenEndpoint: meta.token_endpoint,
    authorizationEndpoint: meta.authorization_endpoint,
  }
}

export async function authorize(page: Page, client: Client, challenge: string, user: string, password: string): Promise<string> {
  const url = new URL(client.authorizationEndpoint)
  url.search = new URLSearchParams({
    response_type: 'code',
    client_id: client.clientId,
    redirect_uri: redirectUri,
    scope: 'openid urn:matrix:org.matrix.msc2967.client:api:* urn:matrix:org.matrix.msc2967.client:device:ELEMENTXTEST',
    state: randomBytes(8).toString('hex'),
    code_challenge: challenge,
    code_challenge_method: 'S256',
  }).toString()
  await page.goto(url.toString())

  await authelia.signIn(page, user, password)
  await authelia.approve(page)

  const handoff = page.getByRole('link', { name: 'Continue', exact: true })
  await expect(handoff).toBeVisible({ timeout: 60_000 })
  const href = await handoff.getAttribute('href')
  expect(href).toMatch(new RegExp(`^${redirectUri}`))
  const code = new URL(href!).searchParams.get('code')
  expect(code).toBeTruthy()
  return code!
}

export async function exchange(request: APIRequestContext, client: Client, code: string, verifier: string): Promise<Tokens> {
  const response = await request.post(client.tokenEndpoint, {
    form: {
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,
      client_id: client.clientId,
      code_verifier: verifier,
    },
  })
  expect(response.status(), await response.text()).toBe(200)
  return response.json()
}

export async function refresh(request: APIRequestContext, client: Client, refreshToken: string): Promise<Tokens> {
  const response = await request.post(client.tokenEndpoint, {
    form: {
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: client.clientId,
    },
  })
  expect(response.status(), await response.text()).toBe(200)
  return response.json()
}

export async function whoami(request: APIRequestContext, accessToken: string) {
  const response = await request.get('/_matrix/client/v3/account/whoami', {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  expect(response.status(), await response.text()).toBe(200)
  return response.json()
}
