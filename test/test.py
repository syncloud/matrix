import os
import struct
import pytest
import requests
import shutil
from os.path import join
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest
from .sso import sso_login, password_login, is_admin
from . import remote_socket
from . import snapd
from .services import SERVICES

TMP_DIR = '/tmp/syncloud'
DIR = os.path.dirname(__file__)

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


@pytest.fixture(scope="session")
def module_setup(request, device, app_dir, artifact_dir):
    def module_teardown():
        device.run_ssh('ls -la /var/snap/matrix/current/config > {0}/config.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/element.json {0}/element.json.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/tuwunel.toml {0}/tuwunel.toml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/livekit.yaml {0}/livekit.yaml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/Caddyfile {0}/Caddyfile.log'.format(TMP_DIR), throw=False)

        device.run_ssh('cp /var/snap/matrix/current/config/whatsapp.yaml {0}/whatsapp.yaml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/appservices/whatsapp.yaml {0}/whatsapp-registration.yaml.log'.format(TMP_DIR), throw=False)

        device.run_ssh('cp /var/snap/matrix/current/config/telegram.yaml {0}/telegram.yaml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/appservices/telegram.yaml {0}/telegram-registration.yaml.log'.format(TMP_DIR), throw=False)

        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl | tail -1000 > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap > {0}/snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap/matrix > {0}/snap.matrix.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap > {0}/var.snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/matrix > {0}/var.snap.matrix.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/matrix/current/ > {0}/var.snap.matrix.current.ls.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('ls -la /var/snap/matrix/current/config/ > {0}/var.snap.matrix.current.config.ls.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('ls -la /var/snap/matrix/common > {0}/var.snap.matrix.common.ls.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('ls -la /data > {0}/data.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /data/matrix > {0}/data.matrix.ls.log'.format(TMP_DIR), throw=False)

        app_log_dir = join(artifact_dir, 'log')
        os.mkdir(app_log_dir)
        device.scp_from_device('/var/snap/matrix/common/log/*.log', app_log_dir)
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, device_host, app, domain):
    add_host_alias(app, device_host, domain)
    add_host_alias('auth', device_host, domain)
    device.run_ssh('date', retries=100)
    snapd.settle(device)
    device.run_ssh('mkdir {0}'.format(TMP_DIR))


def test_activate_device(device):
    response = device.activate_custom()
    assert response.status_code == 200, response.text


def test_install(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_index(app_domain):
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)


def test_matrix(app_domain):
    wait_for_rest(requests.session(), "https://{0}/_matrix/client/versions".format(app_domain), 200, 30)


def test_sso_admin(app_domain, domain, device_user, device_password):
    session = sso_login(app_domain, 'auth.' + domain, device_user, device_password)
    assert session['user_id'] == '@{0}:{1}'.format(device_user, app_domain)
    assert is_admin(app_domain, session['access_token'])


def test_sso_regular_user_is_not_admin(device, app_domain, domain):
    session = device.login()
    added = session.post('https://{0}/rest/users/add'.format(domain), verify=False, json={
        'username': 'regular',
        'password': 'Password1',
        'email': 'regular@{0}'.format(domain),
        'admin': False,
    })
    assert added.status_code == 200, added.text
    login = sso_login(app_domain, 'auth.' + domain, 'regular', 'Password1')
    assert login['user_id'] == '@regular:{0}'.format(app_domain)
    assert not is_admin(app_domain, login['access_token'])


def test_sso_admin_follows_platform_group(device, app_domain, domain):
    session = device.login()
    granted = session.post('https://{0}/rest/users/admin'.format(domain), verify=False,
                           json={'username': 'regular', 'admin': True})
    assert granted.status_code == 200, granted.text
    login = sso_login(app_domain, 'auth.' + domain, 'regular', 'Password1')
    assert is_admin(app_domain, login['access_token'])

    revoked = session.post('https://{0}/rest/users/admin'.format(domain), verify=False,
                           json={'username': 'regular', 'admin': False})
    assert revoked.status_code == 200, revoked.text
    login = sso_login(app_domain, 'auth.' + domain, 'regular', 'Password1')
    assert not is_admin(app_domain, login['access_token'])


def test_password_login_disabled(app_domain, device_user, device_password):
    flows = requests.get("https://{0}/_matrix/client/v3/login".format(app_domain), verify=False)
    assert flows.status_code == 200, flows.text
    types = [flow['type'] for flow in flows.json()['flows']]
    assert 'm.login.password' not in types, flows.text
    assert 'm.login.sso' in types, flows.text
    providers = [idp['name'] for flow in flows.json()['flows'] for idp in flow.get('identity_providers', [])]
    assert 'Syncloud' in providers, flows.text
    response = password_login(app_domain, device_user, device_password)
    assert response.status_code in (400, 403), response.text


def test_sliding_sync(app_domain, domain, device_user, device_password):
    session = sso_login(app_domain, 'auth.' + domain, device_user, device_password)
    headers = {'Authorization': 'Bearer ' + session['access_token']}
    body = {'lists': {'all': {'ranges': [[0, 20]], 'timeline_limit': 1}}}
    url = "https://{0}/_matrix/client/unstable/org.matrix.simplified_msc3575/sync".format(app_domain)
    first = requests.post(url, verify=False, headers=headers, json=body)
    assert first.status_code == 200, first.text
    pos = first.json()['pos']
    assert 'all' in first.json().get('lists', {}), first.text
    second = requests.post(url, verify=False, headers=headers, json=body, params={'pos': pos, 'timeout': 0})
    assert second.status_code == 200, second.text


def test_next_gen_auth_advertised(app_domain):
    metadata = requests.get("https://{0}/_matrix/client/v1/auth_metadata".format(app_domain), verify=False)
    assert metadata.status_code == 200, metadata.text
    assert metadata.json()['issuer'] == 'https://{0}/'.format(app_domain), metadata.text
    assert 'refresh_token' in metadata.json()['grant_types_supported'], metadata.text
    discovery = requests.get("https://{0}/.well-known/openid-configuration".format(app_domain), verify=False)
    assert discovery.status_code == 200, discovery.text
    assert discovery.json()['issuer'] == metadata.json()['issuer'], discovery.text


def test_rtc_transport_advertised(app_domain):
    expected = {'type': 'livekit', 'livekit_service_url': 'https://{0}/livekit/jwt'.format(app_domain)}
    well_known = requests.get("https://{0}/.well-known/matrix/client".format(app_domain), verify=False)
    assert well_known.status_code == 200, well_known.text
    assert well_known.json()['m.homeserver']['base_url'].rstrip('/') == 'https://{0}'.format(app_domain), well_known.text
    assert expected in well_known.json()['org.matrix.msc4143.rtc_foci'], well_known.text


def test_livekit_token(app_domain, domain, device_user, device_password):
    wait_for_rest(requests.session(), "https://{0}/livekit/jwt/healthz".format(app_domain), 200, 30)
    wait_for_rest(requests.session(), "https://{0}/livekit/sfu/".format(app_domain), 200, 30)
    session = sso_login(app_domain, 'auth.' + domain, device_user, device_password)
    headers = {'Authorization': 'Bearer ' + session['access_token']}
    openid = requests.post(
        "https://{0}/_matrix/client/v3/user/{1}/openid/request_token".format(app_domain, session['user_id']),
        verify=False, headers=headers, json={})
    assert openid.status_code == 200, openid.text
    sfu = requests.post("https://{0}/livekit/jwt/sfu/get".format(app_domain), verify=False, json={
        'room': '!call:{0}'.format(app_domain),
        'openid_token': openid.json(),
        'device_id': session['device_id'],
    })
    assert sfu.status_code == 200, sfu.text
    assert sfu.json()['url'] == 'wss://{0}/livekit/sfu'.format(app_domain), sfu.text
    validate = requests.get("https://{0}/livekit/sfu/rtc/validate".format(app_domain), verify=False,
                            params={'access_token': sfu.json()['jwt']})
    assert validate.status_code == 200, validate.text


def stream_probe(device_host, device_password, payload):
    with remote_socket.forwarded(device_host, device_password, '/var/snap/matrix/common/stream.socket') as port:
        return remote_socket.exchange(port, payload)


def test_stream_socket_serves_http(device_host, device_password, app_domain):
    request = 'GET /_matrix/client/versions HTTP/1.1\r\nHost: {0}\r\nConnection: close\r\n\r\n'.format(app_domain).encode()
    reply = stream_probe(device_host, device_password, request)
    assert reply.startswith(b'HTTP/1.1 200'), reply[:200]
    assert b'"versions"' in reply, reply[:500]


@pytest.mark.parametrize('service', SERVICES)
def test_service_started_cleanly(device, service):
    restarts = device.run_ssh('systemctl show -p NRestarts --value snap.matrix.{0}.service'.format(service))
    assert restarts.strip() == '0', restarts


def test_no_tcp_listeners(device):
    sockets = ['livekit.sock', 'turn.sock', 'livekit-jwt.sock', 'matrix.sock', 'stream-http.sock']
    types = device.run_ssh('stat -c %F ' + ' '.join('/var/snap/matrix/current/' + name for name in sockets))
    assert types.splitlines() == ['socket'] * len(sockets), types
    listeners = device.run_ssh('ss -Hlntup')
    ours = [line for line in listeners.splitlines() if '"livekit' in line or '"caddy"' in line]
    assert not [line for line in ours if line.startswith('tcp')], listeners
    for line in ours:
        assert line.split()[4].startswith('127.0.0.1:'), line


def test_stream_socket_routes_turn_to_livekit(device_host, device_password):
    binding = struct.pack('!HHI12s', 0x0001, 0, 0x2112A442, os.urandom(12))
    reply = stream_probe(device_host, device_password, binding)
    assert reply[0:2] == b'\x01\x01', reply.hex()
    assert reply[4:8] == b'\x21\x12\xa4\x42', reply.hex()


def test_sso_redirects_to_authelia(app_domain, domain):
    response = requests.get(
        "https://{0}/_matrix/client/v3/login/sso/redirect".format(app_domain),
        params={'redirectUrl': 'https://{0}/'.format(app_domain)},
        verify=False, allow_redirects=False)
    assert response.status_code in (302, 303, 307), response.text
    assert response.headers['Location'].startswith('https://auth.{0}/'.format(domain)), response.headers


def __log_data_dir(device):
    device.run_ssh('ls -la /data')
    device.run_ssh('mount')
    device.run_ssh('ls -la /data/')
    device.run_ssh('ls -la /data/matrix')


def test_storage_change_event(device):
    device.run_ssh('snap run matrix.storage-change > {0}/storage-change.log'.format(TMP_DIR))


def test_access_change_event(device):
    device.run_ssh('snap run matrix.access-change > {0}/access-change.log'.format(TMP_DIR))


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_upgrade(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)
