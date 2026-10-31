local name = 'matrix';
local browser = 'firefox';
local caddy = '2.11.7-syncloud.1';
local go = '1.24.3-bullseye';
local postgresql = '16-bullseye';
local platform = '26.10.02';
local playwright = 'mcr.microsoft.com/playwright:v1.48.2-jammy';
local tuwunel = '1.9.4-syncloud.10';
local whatsapp = '0.2610.0';
local web_version = '1.12.23';
local signal = '0.2610.0';
local discord = 'bf7bb1190eeae119a66c00a2e0fe59a24bb6a22b';
local go_discord = '1.27-alpine';
local slack = '0.2610.0';
local telegram = '0.2610.0';
local livekit = '1.13.11-syncloud.2';
local livekit_jwt = '0.9.0-syncloud.1';
local alpine = '3.22.0';
local store_publisher = 'stable-346';
local python = '3.12-slim-bookworm';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];
local debian = 'bookworm-slim';

local build(arch, test_ui, dind) = [
  {
    kind: 'pipeline',
    type: 'docker',
    name: arch,
    platform: {
      os: 'linux',
      arch: arch,
    },
    steps: [
      {
        name: 'caddy',
        image: 'debian:bookworm-slim',
        commands: [
          'apt-get update -qq && apt-get install -y -qq wget ca-certificates',
          './caddy/build.sh ' + caddy + ' ' + arch,
        ],
      },
    ] + [
      {
        name: 'caddy test ' + distro,
        image: 'syncloud/platform-' + distro + ':' + platform,
        commands: [
          './caddy/test.sh',
        ],
      }
      for distro in distros
    ] + [
      {
        name: 'cli',
        image: 'golang:1.23',
        commands: [
          './cli/build.sh',
        ],
      },
    ] + [
      {
        name: 'cli test ' + distro,
        image: 'syncloud/platform-' + distro + ':' + platform,
        commands: [
          './cli/test.sh',
        ],
      }
      for distro in distros
    ] + [
      {
        name: 'slack',
        image: 'golang:' + go,
        commands: [
          './get-bridge.sh ' + slack + ' ' + arch + ' slack',
        ],
      },
      {
        name: 'telegram',
        image: 'alpine:' + alpine,
        environment: {
          TELEGRAM_API_ID: {
            from_secret: 'TELEGRAM_API_ID',
          },
          TELEGRAM_API_HASH: {
            from_secret: 'TELEGRAM_API_HASH',
          },
        },
        commands: [
          './telegram/build.sh ' + telegram + ' ' + arch,
        ],
      },
      {
        name: 'web',
        image: 'debian:' + debian,
        commands: [
          './web/build.sh ' + web_version,
        ],
      },
      {
        name: 'signal',
        image: 'alpine:' + alpine,
        commands: [
          './get-bridge.sh ' + signal + ' ' + arch + ' signal',
        ],
      },
      {
        name: 'tuwunel',
        image: 'alpine:' + alpine,
        commands: [
          './tuwunel/build.sh ' + tuwunel + ' ' + arch,
        ],
      },
      {
        name: 'livekit',
        image: 'alpine:' + alpine,
        commands: [
          './livekit/build.sh ' + livekit + ' ' + livekit_jwt + ' ' + arch,
        ],
      },
    ] + [
      {
        name: 'livekit test ' + distro,
        image: 'syncloud/platform-' + distro + ':' + platform,
        commands: [
          './livekit/test.sh',
        ],
      }
      for distro in distros
    ] + [
      {
        name: 'discord',
        image: 'golang:' + go_discord,
        commands: [
          './discord/build.sh ' + discord,
        ],
      },
      {
        name: 'whatsapp',
        image: 'alpine:' + alpine,
        commands: [
          './get-bridge.sh ' + whatsapp + ' ' + arch + ' whatsapp',
        ],
      },
      {
        name: 'postgresql',
        image: 'postgres:' + postgresql,
        commands: [
          './postgresql/build.sh',
        ],
      },
      {
        name: 'package',
        image: 'debian:' + debian,
        commands: [
          './package.sh ' + name + ' $DRONE_BUILD_NUMBER',
        ],
      },
    ] + [
      {
        name: 'test ' + distro,
        image: 'python:' + python,
        commands: [
          './ci/test.sh test.py ' + distro + ' ' + name + ' ' + arch,
        ],
      }
      for distro in distros
    ] + (if test_ui then [
           {
             name: 'test-ui',
             image: playwright,
             commands: [
               './test/e2e/run.sh ' + distro_default + ' specs desktop',
             ],
           },
         ] else []) + [
      {
        name: 'test-upgrade',
        image: 'python:' + python,
        commands: [
          './ci/test.sh upgrade.py ' + distro_default + ' ' + name + ' ' + arch,
        ],
      },
      {
        name: 'publish',
        image: 'syncloud/store-publisher:' + store_publisher,
        environment: {
          SYNCLOUD_TOKEN: {
            from_secret: 'SYNCLOUD_TOKEN',
          },
        },
        command: ['snap', '-c', '${DRONE_BRANCH}'],
        when: {
          branch: ['stable'],
          event: ['push'],
        },
      },
      {
        name: 'artifact',
        image: 'appleboy/drone-scp:1.6.4',
        settings: {
          host: {
            from_secret: 'artifact_host',
          },
          username: 'artifact',
          key: {
            from_secret: 'artifact_key',
          },
          timeout: '2m',
          command_timeout: '2m',
          target: '/home/artifact/repo/' + name + '/${DRONE_BUILD_NUMBER}-' + arch,
          source: 'artifact/*',
          strip_components: 1,
        },
        when: {
          status: ['failure', 'success'],
          event: ['push'],
        },
      },
    ],
    trigger: {
      event: [
        'push',
      ],
    },
    services: [
      {
        name: 'docker',
        image: 'docker:' + dind,
        privileged: true,
        volumes: [
          {
            name: 'dockersock',
            path: '/var/run',
          },
        ],
      },
    ] + [
      {
        name: name + '.' + distro + '.com',
        image: 'syncloud/platform-' + distro + ':' + platform,
        privileged: true,
        entrypoint: ['/bin/sh', '-c', "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"],
        volumes: [
          {
            name: 'dbus',
            path: '/var/run/dbus',
          },
          {
            name: 'dev',
            path: '/dev',
          },
        ],
      }
      for distro in distros
    ],
    volumes: [
      {
        name: 'dbus',
        host: {
          path: '/var/run/dbus',
        },
      },
      {
        name: 'dev',
        host: {
          path: '/dev',
        },
      },
      {
        name: 'dockersock',
        temp: {},
      },
    ],
  },
];

build('amd64', true, '20.10.21-dind') +
build('arm64', false, '20.10.21-dind')

