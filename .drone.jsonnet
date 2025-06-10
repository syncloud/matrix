local name = 'matrix';
local browser = 'firefox';
local nginx = '1.24.0';
local go = '1.24.3';
local postgresql = '15-bullseye';
local platform = '25.02';
local selenium = '4.21.0-20240517';
local dendrite = 'syncloud-0.14.0';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';
local python = '3.9-slim-buster';
local distro_default = 'buster';
local distros = ['bookworm', 'buster'];

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
        name: 'version',
        image: 'debian:buster-slim',
        commands: [
          'echo $DRONE_BUILD_NUMBER > version',
        ],
      },
      {
        name: 'nginx',
        image: 'nginx:' + nginx,
        commands: [
          './nginx/build.sh',
        ],
      },
      {
        name: 'nginx test',
        image: 'syncloud/platform-buster-' + arch + ':' + platform,
        commands: [
          './nginx/test.sh',
        ],
      },
      {
        name: 'cli',
        image: 'golang:1.20',
        commands: [
          'cd cli',
          "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/install ./cmd/install",
          "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/configure ./cmd/configure",
          "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/pre-refresh ./cmd/pre-refresh",
          "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/post-refresh ./cmd/post-refresh",
          "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/bin/cli ./cmd/cli",
        ],
      }
      {
        name: 'web',
        image: 'debian:buster-slim',
        commands: [
          './web/build.sh',
        ],
      },
      {
        name: 'build signald',
        image: 'docker:' + dind,
        commands: [
          './signal/build.sh',
        ],
        volumes: [
          {
            name: 'dockersock',
            path: '/var/run',
          },
        ],
      },
      {
        name: 'build matrix',
        image: 'golang:' + go,
        commands: [
          './matrix/build.sh ' + dendrite,
        ],
      },
      {
        name: 'sliding-sync',
        image: 'golang:' + go,
        commands: [
          './sliding-sync/build.sh',
        ],
      },
      {
        name: 'slack',
        image: 'golang:' + go,
        commands: [
          './slack/build.sh',
        ],
      },
      {
        name: 'discord',
        image: 'golang:' + go,
        commands: [
          './discord/build.sh',
        ],
      },
      {
        name: 'whatsapp',
        image: 'golang:' + go,
        commands: [
          './whatsapp/build.sh',
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
        name: 'python',
        image: 'docker:' + dind,
        commands: [
          './python/build.sh',
        ],
        volumes: [
          {
            name: 'dockersock',
            path: '/var/run',
          },
        ],
      },
      {
        name: 'telegram',
        image: 'debian:buster-slim',
        environment: {
          TELEGRAM_API_ID: {
            from_secret: 'TELEGRAM_API_ID',
          },
          TELEGRAM_API_HASH: {
            from_secret: 'TELEGRAM_API_HASH',
          },
        },
        commands: [
          './telegram/build.sh',
        ],
      },
      {
        name: 'package',
        image: 'debian:buster-slim',
        commands: [
          'VERSION=$(cat version)',
          './package.sh ' + name + ' $VERSION ',
        ],
      },
    ] + [
      {
        name: 'test ' + distro,
        image: 'python:' + python,
        commands: [
          'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
          'cd test',
          './deps.sh',
          'py.test -x -s test.py --distro=' + distro + ' --domain=' + distro + '.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.' + distro + '.com --app=' + name + ' --arch=' + arch,
        ],
      }
      for distro in distros
    ] + (if test_ui then [
           {
             name: 'selenium',
             image: 'selenium/standalone-' + browser + ':' + selenium,
             detach: true,
             environment: {
               SE_NODE_SESSION_TIMEOUT: '999999',
               START_XVFB: 'true',
             },
             volumes: [{
               name: 'shm',
               path: '/dev/shm',
             }],
             commands: [
               'cat /etc/hosts',
               'DOMAIN="' + distro_default + '.com"',
               'APP_DOMAIN="' + name + '.' + distro_default + '.com"',
               'getent hosts $APP_DOMAIN | sed "s/$APP_DOMAIN/auth.$DOMAIN/g" | sudo tee -a /etc/hosts',
               'cat /etc/hosts',
               '/opt/bin/entry_point.sh',
             ],
           },
           {
             name: 'selenium-video',
             image: 'selenium/video:ffmpeg-6.1.1-20240621',
             detach: true,
             environment: {
               DISPLAY_CONTAINER_NAME: 'selenium',
               FILE_NAME: 'video.mkv',
             },
             volumes: [
               {
                 name: 'shm',
                 path: '/dev/shm',
               },
               {
                 name: 'videos',
                 path: '/videos',
               },
             ],
           },
           {
             name: 'test-ui',
             image: 'python:' + python,
             commands: [
               'cd test',
               './deps.sh',
               'py.test -x -s ui.py --distro=' + distro_default + ' --ui-mode=desktop --domain=' + distro_default + '.com --device-host=' + name + '.' + distro_default + '.com --app=' + name + ' --browser-height=2000 --browser=' + browser,
             ],
             volumes: [{
               name: 'videos',
               path: '/videos',
             }],
           },

         ] else []) + [
      {
        name: 'test-upgrade',
        image: 'python:' + python,
        commands: [
          'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
          'cd test',
          './deps.sh',
          'py.test -x -s test-upgrade.py --distro=' + distro_default + '  --ui-mode=desktop --domain=' + distro_default + '.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.' + distro_default + '.com --app=' + name + ' --browser=' + browser,
        ],
      },
      {
        name: 'upload',
        image: 'debian:buster-slim',
        environment: {
          AWS_ACCESS_KEY_ID: {
            from_secret: 'AWS_ACCESS_KEY_ID',
          },
          AWS_SECRET_ACCESS_KEY: {
            from_secret: 'AWS_SECRET_ACCESS_KEY',
          },
          SYNCLOUD_TOKEN: {
            from_secret: 'SYNCLOUD_TOKEN',
          },
        },
        commands: [
          'PACKAGE=$(cat package.name)',
          'apt update && apt install -y wget',
          'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
          'chmod +x release',
          './release publish -f $PACKAGE -b $DRONE_BRANCH',
        ],
        when: {
          branch: ['stable', 'master'],
          event: ['push'],
        },
      },
      {
        name: 'promote',
        image: 'debian:buster-slim',
        environment: {
          AWS_ACCESS_KEY_ID: {
            from_secret: 'AWS_ACCESS_KEY_ID',
          },
          AWS_SECRET_ACCESS_KEY: {
            from_secret: 'AWS_SECRET_ACCESS_KEY',
          },
          SYNCLOUD_TOKEN: {
            from_secret: 'SYNCLOUD_TOKEN',
          },
        },
        commands: [
          'apt update && apt install -y wget',
          'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
          'chmod +x release',
          './release promote -n ' + name + ' -a $(dpkg --print-architecture)',
        ],
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
        'pull_request',
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
        image: 'syncloud/platform-' + distro + '-' + arch + ':' + platform,
        privileged: true,
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
        name: 'shm',
        temp: {},
      },
      {
        name: 'dockersock',
        temp: {},
      },
      {
        name: 'videos',
        temp: {},
      },
    ],
  },
  {
    kind: 'pipeline',
    type: 'docker',
    name: 'promote-' + arch,
    platform: {
      os: 'linux',
      arch: arch,
    },
    steps: [
      {
        name: 'promote',
        image: 'debian:buster-slim',
        environment: {
          AWS_ACCESS_KEY_ID: {
            from_secret: 'AWS_ACCESS_KEY_ID',
          },
          AWS_SECRET_ACCESS_KEY: {
            from_secret: 'AWS_SECRET_ACCESS_KEY',
          },
        },
        commands: [
          'apt update && apt install -y wget',
          'wget https://github.com/syncloud/snapd/releases/download/1/syncloud-release-' + arch + ' -O release --progress=dot:giga',
          'chmod +x release',
          './release promote -n ' + name + ' -a $(dpkg --print-architecture)',
        ],
      },
    ],
    trigger: {
      event: [
        'promote',
      ],
    },
  },
];

build('amd64', true, '20.10.21-dind') +
build('arm64', false, '19.03.8-dind')
