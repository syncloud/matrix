import os
import pytest
import requests
import shutil
from os.path import join
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest

TMP_DIR = '/tmp/syncloud'

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


@pytest.fixture(scope="session")
def module_setup(request, device, app_dir, artifact_dir):
    def module_teardown():
        device.run_ssh('ls -la /var/snap/matrix/current/config > {0}/config.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/element.json {0}/element.json.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/matrix.yaml {0}/matrix.yaml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/whatsapp.yaml {0}/whatsapp.yaml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/matrix/current/config/whatsapp-registration.yaml {0}/whatsapp-registration.yaml.log'.format(TMP_DIR), throw=False)
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
    device.run_ssh('date', retries=100)
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


def test_sync(app_domain):
    #TODO: fox to use post
    wait_for_rest(requests.session(), "https://{0}/_matrix/client/unstable/org.matrix.msc3575/sync".format(app_domain), 405, 10)
