# Matrix for Syncloud

A [Matrix](https://matrix.org) homeserver packaged as a one-click app for
[Syncloud](https://syncloud.org), an open-source self-hosting platform that lets
non-technical users run mainstream open-source apps on their own device with a domain
name and automatic HTTPS.

Listed on the Matrix [distributions page](https://matrix.org/ecosystem/distributions/).

## What's included

| Component | Role |
| --- | --- |
| [Tuwunel](https://github.com/cyberb/tuwunel) (fork with a Dendrite importer) | Matrix homeserver |
| [Element Web](https://github.com/element-hq/element-web) | Web client, served at the app's domain |
| PostgreSQL | Bridge database |
| [Caddy](https://caddyserver.com) with [caddy-l4](https://github.com/mholt/caddy-l4) | Serves the client and `.well-known`, proxies to the homeserver and LiveKit, and splits TURN from HTTP on the app's stream socket |
| [mautrix-whatsapp](https://github.com/mautrix/whatsapp) | WhatsApp bridge |
| [mautrix-telegram](https://github.com/mautrix/telegram) | Telegram bridge |
| [mautrix-signal](https://github.com/mautrix/signal) | Signal bridge |
| [mautrix-slack](https://github.com/mautrix/slack) | Slack bridge |
| [mautrix-discord](https://github.com/mautrix/discord) (`megadiscord` branch, bridgev2) | Discord bridge |
| [LiveKit](https://github.com/livekit/livekit) | Media server (SFU) for Element Call |
| [lk-jwt-service](https://github.com/element-hq/lk-jwt-service) | Issues LiveKit tokens to Matrix users |

Exact pinned versions are defined at the top of [`.drone.jsonnet`](.drone.jsonnet).

### Tuwunel fork

The homeserver is [Tuwunel](https://github.com/matrix-construct/tuwunel), built from
[cyberb/tuwunel](https://github.com/cyberb/tuwunel) (`syncloud` branch). The only
addition is a `server import-dendrite` admin command used once to upgrade existing
installs in place from the previous Dendrite homeserver: the signing key, accounts,
devices and access tokens, profiles, account data, end-to-end keys and key backups,
rooms with their history and state, aliases and media are carried over.

The fork also lets Tuwunel reach bridges and the identity provider over unix sockets,
and maps the identity provider's `groups` claim to server admins.

Tuwunel provides native sliding sync. It stores its data in RocksDB under `$SNAP_DATA`;
media lives on app storage. All local traffic (Caddy, bridges, Authelia, PostgreSQL)
goes over unix sockets.

### Sign-in

Sign-in goes through the platform's Authelia only; password login on the homeserver
is disabled, so Authelia's two-factor policy applies to every new session.

- **Element X** and other next-gen-auth clients use Tuwunel's built-in OAuth server,
  which brokers to Authelia and asks the user to approve each new app once.
- **Element Web/Android/iOS, FluffyChat** and other SSO clients show "Continue with
  Syncloud" and open the browser for Authelia.
- Members of the platform's `syncloud` group are server admins; this follows the
  group on every sign-in.

Sessions carried over from Dendrite keep working without signing in again.

### Calls

Voice and video calls use Element Call (MatrixRTC), in Element Web and Element X alike,
for both 1:1 and group calls. The homeserver advertises the bundled LiveKit SFU, and
Element Web uses its built-in Element Call for every call.

Calls need no router ports at all: all call media goes through port 443. LiveKit listens
on loopback only and its built-in TURN server is offered to clients as
`turns:<app domain>:443`; the platform hands the app its raw TLS streams
(`/var/snap/matrix/common/stream.socket`), and Caddy sends TURN connections to LiveKit
and everything else to the web server. Calls therefore need a platform with stream socket
support.

Built for `amd64` and `arm64`.

## Install

Install Syncloud on your device, then install Matrix from the app store. See the
[Syncloud platform](https://github.com/syncloud/platform) repository and
[syncloud.org](https://syncloud.org) for supported devices and setup.

The app is packaged as a snap and keeps all state in `$SNAP_DATA`, so it participates
in the platform's backup and restore.

## Build

CI builds every commit for both architectures on
[Drone](http://ci.syncloud.org:8080/syncloud/matrix), running integration and browser
tests against a real platform install.

To generate `.drone.yml` from the jsonnet source and run a pipeline locally:

```
drone jsonnet --stdout --stream > .drone.yml
drone exec --pipeline amd64 --trusted .drone.yml
```

Porting notes for Syncloud apps in general:
[App porting guide](https://github.com/syncloud/platform/wiki/App-porting-guide).

## Support

Community support is available at [syncloud.org](https://syncloud.org). A subscription
with commercial support is also offered.

## Licence

[GPL-3.0](LICENSE)
