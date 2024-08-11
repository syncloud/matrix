local name = 'matrix';
local browser = 'firefox';
local nginx = '1.24.0';
local go = '1.22.6-bullseye';
local postgresql = "15-bullseye";
local platform = '24.05';
local selenium = '4.21.0-20240517';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';

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
          './matrix/build.sh',
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
            name: "postgresql",
            image: "postgres:" + postgresql,
            commands: [
                "./postgresql/build.sh"
            ]

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
      {
        name: 'test',
        image: 'python:3.8-slim-buster',
        commands: [
          'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
          'cd integration',
          './deps.sh',
          'py.test -x -s verify.py --distro=buster --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.buster.com --app=' + name + ' --arch=' + arch,
        ],
      },
    ] + (if test_ui then [
{
            name: "selenium",
            image: "selenium/standalone-" + browser + ":" + selenium,
            detach: true,
            environment: {
                SE_NODE_SESSION_TIMEOUT: "999999",
                START_XVFB: "true"
            },
               volumes: [{
                name: "shm",
                path: "/dev/shm"
            }],
            commands: [
                "cat /etc/hosts",
                "getent hosts " + name + ".buster.com | sed 's/" + name +".buster.com/auth.buster.com/g' | sudo tee -a /etc/hosts",
                "cat /etc/hosts",
                "/opt/bin/entry_point.sh"
            ]
         },

        {
            name: "selenium-video",
            image: "selenium/video:ffmpeg-6.1.1-20240621",
            detach: true,
            environment: {
                DISPLAY_CONTAINER_NAME: "selenium",
                FILE_NAME: "video.mkv"
            },
            volumes: [
                {
                    name: "shm",
                    path: "/dev/shm"
                },
               {
                    name: "videos",
                    path: "/videos"
                }
            ]
        },
           {
             name: 'test-ui',
             image: 'python:3.8-slim-buster',
             commands: [
               'cd integration',
               './deps.sh',
               'py.test -x -s test-ui.py --distro=buster --ui-mode=desktop --domain=buster.com --device-host=' + name + '.buster.com --app=' + name + ' --browser=' + browser,
             ],
             volumes: [{
               name: 'videos',
               path: '/videos',
             }],
           },

         ] else []) + [
      {
        name: 'test-upgrade',
        image: 'python:3.8-slim-buster',
        commands: [
          'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
          'cd integration',
          './deps.sh',
          'py.test -x -s test-upgrade.py --distro=buster --ui-mode=desktop --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.buster.com --app=' + name + ' --browser=' + browser,
        ],
      },
      {
              name: "upload",
              image: "debian:buster-slim",
              environment: {
                  AWS_ACCESS_KEY_ID: {
                      from_secret: "AWS_ACCESS_KEY_ID"
                  },
                  AWS_SECRET_ACCESS_KEY: {
                      from_secret: "AWS_SECRET_ACCESS_KEY"
                  },
                  SYNCLOUD_TOKEN: {
                           from_secret: "SYNCLOUD_TOKEN"
                       }
              },
              commands: [
                  "PACKAGE=$(cat package.name)",
                  "apt update && apt install -y wget",
                  "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
                  "chmod +x release",
                  "./release publish -f $PACKAGE -b $DRONE_BRANCH"
              ],
              when: {
                  branch: ["stable", "master"],
      	    event: [ "push" ]
      }
          },
          {
                  name: "promote",
                  image: "debian:buster-slim",
                  environment: {
                      AWS_ACCESS_KEY_ID: {
                          from_secret: "AWS_ACCESS_KEY_ID"
                      },
                      AWS_SECRET_ACCESS_KEY: {
                          from_secret: "AWS_SECRET_ACCESS_KEY"
                      },
                       SYNCLOUD_TOKEN: {
                           from_secret: "SYNCLOUD_TOKEN"
                       }
                  },
                  commands: [
                    "apt update && apt install -y wget",
                    "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
                    "chmod +x release",
                    "./release promote -n " + name + " -a $(dpkg --print-architecture)"
                  ],
                  when: {
                      branch: ["stable"],
                      event: ["push"]
                  }
            },
              {
                  name: "artifact",
                  image: "appleboy/drone-scp:1.6.4",
                  settings: {
                      host: {
                          from_secret: "artifact_host"
                      },
                      username: "artifact",
                      key: {
                          from_secret: "artifact_key"
                      },
                      timeout: "2m",
                      command_timeout: "2m",
                      target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + arch,
                      source: "artifact/*",
      		             strip_components: 1
                  },
                  when: {
                    status: [ "failure", "success" ],
                    event: [ "push" ]
                  }
              }
          ],
           trigger: {
             event: [
               "push",
               "pull_request"
             ]
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
      {
        name: name + '.buster.com',
        image: 'syncloud/platform-buster-' + arch + ':' + platform,
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
      },
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
