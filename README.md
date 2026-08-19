# Matrix for Syncloud

A [Matrix](https://matrix.org) homeserver packaged as a one-click app for
[Syncloud](https://syncloud.org), an open-source self-hosting platform that lets
non-technical users run mainstream open-source apps on their own device with a domain
name and automatic HTTPS.

Listed on the Matrix [distributions page](https://matrix.org/ecosystem/distributions/).

## What's included

| Component | Role |
| --- | --- |
| [Dendrite](https://github.com/cyberb/dendrite) (patched fork) | Matrix homeserver |
| [Element Web](https://github.com/element-hq/element-web) | Web client, served at the app's domain |
| PostgreSQL | Homeserver and bridge database |
| nginx | Reverse proxy, serves the client and the `.well-known` delegation endpoints |
| [mautrix-whatsapp](https://github.com/mautrix/whatsapp) | WhatsApp bridge |
| [mautrix-telegram](https://github.com/mautrix/telegram) | Telegram bridge |
| [mautrix-signal](https://github.com/mautrix/signal) | Signal bridge |
| [mautrix-slack](https://github.com/mautrix/slack) | Slack bridge |
| [mautrix-discord](https://github.com/mautrix/discord) | Discord bridge |

Exact pinned versions are defined at the top of [`.drone.jsonnet`](.drone.jsonnet).

### Dendrite fork

The homeserver is built from [cyberb/dendrite](https://github.com/cyberb/dendrite), a
fork of [element-hq/dendrite](https://github.com/element-hq/dendrite) carrying patches
that are not upstream:

- native sliding sync (MSC4186), with MSC3266 room summary and MSC4115 membership
- LDAP authentication
- MSC3706 partial-state federation join fix
- appservice namespace authorisation fix, so bridges do not fail at startup
- advertises spec v1.3 and v1.4

Not included: MatrixRTC (LiveKit SFU, `lk-jwt-service`, Element Call). Group calls are
not available; only 1:1 WebRTC calls between clients that support them.

Built for `amd64` and `arm64`.

## Install

Install Syncloud on your device, then install Matrix from the app store. See the
[Syncloud platform](https://github.com/syncloud/platform) repository and
[syncloud.org](https://syncloud.org) for supported devices and setup.

The app is packaged as a snap. It runs under strict confinement and keeps all state in
`$SNAP_DATA`, so it participates in the platform's backup and restore.

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
