import hashlib
import time

import pytest
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from subprocess import check_output, run
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest
from .sso import sso_login, password_login, is_admin
from . import snapd
from .services import SERVICES

TMP_DIR = '/tmp/syncloud'
BRIDGES = ['whatsapp', 'telegram', 'signal', 'slack', 'discord']
IMAGE = bytes(range(256)) * 64

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir):
    def module_teardown():
        device.run_ssh('journalctl > {0}/refresh.journalctl.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), artifact_dir)
        run('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


@pytest.fixture(scope="module")
def state():
    return {}


def api(app_domain, method, path, token=None, **kwargs):
    headers = kwargs.pop('headers', {})
    if token:
        headers['Authorization'] = 'Bearer ' + token
    for _ in range(30):
        response = requests.request(method, 'https://{0}{1}'.format(app_domain, path),
                                    headers=headers, verify=False, **kwargs)
        if response.status_code not in (429, 502, 503):
            return response
        time.sleep(2)
    return response


def test_start(module_setup, app, device_host, domain, device):
    add_host_alias(app, device_host, domain)
    add_host_alias('auth', device_host, domain)
    device.activated()
    snapd.settle(device)
    device.run_ssh('rm -rf {0}'.format(TMP_DIR), throw=False)
    device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)


def test_install_store_version(device, app_domain):
    device.run_ssh('snap remove matrix')
    device.run_ssh('snap install matrix', retries=10)
    wait_for_rest(requests.session(), "https://{0}/_matrix/client/versions".format(app_domain), 200, 60)


def test_populate(app_domain, domain, device_user, device_password, state):
    session = sso_login(app_domain, 'auth.' + domain, device_user, device_password)
    token = session['access_token']
    user_id = session['user_id']
    state.update(token=token, user_id=user_id, device_id=session['device_id'])

    upload = api(app_domain, 'POST', '/_matrix/media/v3/upload?filename=upgrade.bin', token,
                 data=IMAGE, headers={'Content-Type': 'application/octet-stream'})
    assert upload.status_code == 200, upload.text
    state['mxc'] = upload.json()['content_uri']

    room = api(app_domain, 'POST', '/_matrix/client/v3/createRoom', token,
               json={'name': 'upgrade room', 'room_alias_name': 'upgrade'})
    assert room.status_code == 200, room.text
    state['room'] = room.json()['room_id']

    events = []
    for i in range(3):
        sent = api(app_domain, 'PUT', '/_matrix/client/v3/rooms/{0}/send/m.room.message/u{1}'.format(state['room'], i),
                   token, json={'msgtype': 'm.text', 'body': 'before upgrade {0}'.format(i)})
        assert sent.status_code == 200, sent.text
        events.append(sent.json()['event_id'])
    state['events'] = events

    data = api(app_domain, 'PUT', '/_matrix/client/v3/user/{0}/account_data/org.syncloud.upgrade'.format(user_id),
               token, json={'value': 'kept'})
    assert data.status_code == 200, data.text

    name = api(app_domain, 'PUT', '/_matrix/client/v3/profile/{0}/displayname'.format(user_id),
               token, json={'displayname': 'Upgrade User'})
    assert name.status_code == 200, name.text

    key = api(app_domain, 'GET', '/_matrix/key/v2/server').json()
    state['server_keys'] = sorted(key['verify_keys'])


def test_upgrade(device_host, device_password, app_archive_path, app_domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}/_matrix/client/versions".format(app_domain), 200, 60)


@pytest.mark.parametrize('service', SERVICES)
def test_service_started_cleanly_after_upgrade(device, service):
    restarts = device.run_ssh('systemctl show -p NRestarts --value snap.matrix.{0}.service'.format(service))
    assert restarts.strip() == '0', restarts


def test_homeserver_is_tuwunel(app_domain):
    response = api(app_domain, 'GET', '/_matrix/federation/v1/version')
    assert response.status_code == 200, response.text
    assert response.json()['server']['name'].lower() == 'tuwunel', response.text


def test_session_survives(app_domain, state):
    response = api(app_domain, 'GET', '/_matrix/client/v3/account/whoami', state['token'])
    assert response.status_code == 200, response.text
    assert response.json()['user_id'] == state['user_id']
    assert response.json()['device_id'] == state['device_id']


def test_history_migrated(app_domain, state):
    response = api(app_domain, 'GET', '/_matrix/client/v3/rooms/{0}/messages?dir=b&limit=50'.format(state['room']),
                   state['token'])
    assert response.status_code == 200, response.text
    ids = [event['event_id'] for event in response.json()['chunk']]
    for event_id in state['events']:
        assert event_id in ids, ids


def test_alias_migrated(app_domain, state):
    alias = '%23upgrade:{0}'.format(app_domain)
    response = api(app_domain, 'GET', '/_matrix/client/v3/directory/room/{0}'.format(alias))
    assert response.status_code == 200, response.text
    assert response.json()['room_id'] == state['room']


def test_profile_and_account_data_migrated(app_domain, state):
    profile = api(app_domain, 'GET', '/_matrix/client/v3/profile/{0}'.format(state['user_id']), state['token'])
    assert profile.status_code == 200, profile.text
    assert profile.json().get('displayname') == 'Upgrade User', profile.text
    data = api(app_domain, 'GET', '/_matrix/client/v3/user/{0}/account_data/org.syncloud.upgrade'.format(state['user_id']),
               state['token'])
    assert data.status_code == 200, data.text
    assert data.json()['value'] == 'kept'


def test_media_migrated(app_domain, state):
    server, media_id = state['mxc'][len('mxc://'):].split('/')
    response = api(app_domain, 'GET', '/_matrix/client/v1/media/download/{0}/{1}'.format(server, media_id),
                   state['token'])
    assert response.status_code == 200, response.text
    assert hashlib.sha256(response.content).hexdigest() == hashlib.sha256(IMAGE).hexdigest()


def test_signing_key_migrated(app_domain, state):
    key = api(app_domain, 'GET', '/_matrix/key/v2/server').json()
    assert sorted(key['verify_keys']) == state['server_keys'], key


def test_password_login_refused_after_upgrade(app_domain, device_user, device_password):
    response = password_login(app_domain, device_user, device_password)
    assert response.status_code in (400, 403), response.text


def test_sso_login_after_upgrade(app_domain, domain, device_user, device_password, state):
    session = sso_login(app_domain, 'auth.' + domain, device_user, device_password)
    assert session['user_id'] == state['user_id']
    sent = api(app_domain, 'PUT', '/_matrix/client/v3/rooms/{0}/send/m.room.message/after'.format(state['room']),
               session['access_token'], json={'msgtype': 'm.text', 'body': 'after upgrade'})
    assert sent.status_code == 200, sent.text
    state['sso_token'] = session['access_token']


def test_sso_admin_after_upgrade(app_domain, state):
    assert is_admin(app_domain, state['sso_token'])


@pytest.mark.parametrize('bridge', BRIDGES)
def test_bridge_registered(app_domain, state, bridge):
    bot = '@{0}bot:{1}'.format(bridge, app_domain)
    for _ in range(60):
        response = api(app_domain, 'GET', '/_matrix/client/v3/profile/{0}'.format(bot), state['token'])
        if response.status_code == 200:
            return
        time.sleep(2)
    assert response.status_code == 200, response.text


@pytest.mark.parametrize('bridge', BRIDGES)
def test_bridge_responds(app_domain, state, bridge):
    bot = '@{0}bot:{1}'.format(bridge, app_domain)
    room = api(app_domain, 'POST', '/_matrix/client/v3/createRoom', state['token'],
               json={'is_direct': True, 'invite': [bot], 'preset': 'trusted_private_chat'})
    assert room.status_code == 200, room.text
    room_id = room.json()['room_id']

    joined = []
    for _ in range(60):
        members = api(app_domain, 'GET', '/_matrix/client/v3/rooms/{0}/joined_members'.format(room_id), state['token'])
        joined = list(members.json().get('joined', {}))
        if bot in joined:
            break
        time.sleep(2)
    assert bot in joined, joined

    sent = api(app_domain, 'PUT', '/_matrix/client/v3/rooms/{0}/send/m.room.message/help'.format(room_id),
               state['token'], json={'msgtype': 'm.text', 'body': 'help'})
    assert sent.status_code == 200, sent.text

    replies = []
    for _ in range(60):
        messages = api(app_domain, 'GET', '/_matrix/client/v3/rooms/{0}/messages?dir=b&limit=20'.format(room_id),
                       state['token'])
        replies = [event for event in messages.json().get('chunk', [])
                   if event['sender'] == bot and event['type'] == 'm.room.message']
        if replies:
            break
        time.sleep(2)
    assert replies, messages.text


def test_log_errors(device):
    assert "Unsupported database" not in device.run_ssh('journalctl -u snap.matrix.*')
