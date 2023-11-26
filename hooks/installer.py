import logging
import shutil
import uuid
import re
import os
from os import path
from os.path import isfile
from os.path import join
from os.path import realpath
from subprocess import check_output, CalledProcessError

from syncloudlib import fs, linux, gen, logger
from syncloudlib.application import paths, urls, storage, service

from postgres import Database

APP_NAME = 'matrix'

INSTALL_USER = 'installer'
USER_NAME = APP_NAME
DB_NAME = APP_NAME
DB_USER = APP_NAME
DB_PASSWORD = APP_NAME
LOG_PATH = 'log/{0}.log'.format(APP_NAME)
CRON_USER = APP_NAME
APP_CONFIG_PATH = '{0}/config'.format(APP_NAME)
PSQL_PORT = 5436

SYSTEMD_NGINX = '{0}.nginx'.format(APP_NAME)
SYSTEMD_POSTGRESQL = '{0}.postgresql'.format(APP_NAME)
SYSTEMD_MATRIX = '{0}.matrix'.format(APP_NAME)

class Installer:
    def __init__(self):
        if not logger.factory_instance:
            logger.init(logging.DEBUG, True)

        self.log = logger.get_logger('matrix_installer')
        self.app_dir = paths.get_app_dir(APP_NAME)
        self.common_dir = paths.get_data_dir(APP_NAME)
        self.data_dir = join('/var/snap', APP_NAME, 'current')
        self.config_dir = join(self.data_dir, 'config')
        self.db = Database(self.app_dir, self.data_dir, self.config_dir, PSQL_PORT, DB_USER)
        self.install_file = join(self.common_dir, 'installed')
        self.new_version = join(self.app_dir, 'version')
        self.current_version = join(self.data_dir, 'version')
        self.sync_secret_file = join(self.data_dir, 'sync.secret')
        self.telegram_registration_config = '{0}/telegram-registration.yaml'.format(self.config_dir)

    def install_config(self):

        home_folder = join('/home', USER_NAME)
        linux.useradd(USER_NAME, home_folder=home_folder)
        storage.init_storage(APP_NAME, USER_NAME)
        templates_path = join(self.app_dir, 'config')

        variables = {
            'app_dir': self.app_dir,
            'common_dir': self.common_dir,
            'data_dir': self.data_dir,
            'db_psql_port': PSQL_PORT,
            'database_dir': self.db.database_dir,
            'config_dir': self.config_dir,
            'domain': urls.get_app_domain_name(APP_NAME)
        }
        gen.generate_files(templates_path, self.config_dir, variables, variable_tags=('{{{', '}}}'))

        fs.makepath(join(self.common_dir, 'log'))
        fs.makepath(join(self.common_dir, 'nginx'))
        fs.makepath(join(self.data_dir, 'data'))
        self.register_whatsapp()
        self.register_telegram()
        self.fix_permissions()

    def register_whatsapp(self):
        check_output([
            '{0}/bin/whatsapp'.format(self.app_dir),
            '-g',
            '-c', '{0}/whatsapp.yaml'.format(self.config_dir),
            '-r', '{0}/whatsapp-registration.yaml'.format(self.config_dir)
        ])

    def register_telegram(self):
        check_output([
            '{0}/python/bin/python'.format(self.app_dir),
            '-m', 'mautrix_telegram',
            '-g',
            '-c', '{0}/telegram.yaml'.format(self.config_dir),
            '-r', '{0}'.format(self.telegram_registration_config)
        ])

    def install(self):
        check_output([
            f'{self.app_dir}/matrix/bin/generate-keys',
            '--private-key', '/var/snap/matrix/current/private_key.pem'
        ])
        self.install_config()
        self.db.init()
        self.db.init_config()

    def pre_refresh(self):
        self.db.backup()

    def post_refresh(self):
        self.install_config()
        self.db.remove()
        self.db.init()
        self.db.init_config()
        self.clear_version()

    def configure(self):
        if path.isfile(self.install_file):
            self.upgrade()
        else:
            self.initialize()
        storage.init_storage(APP_NAME, USER_NAME)

    def upgrade(self):
        self.db.restore()
        self.prepare_storage()
        self.create_db()
        self.set_sync_secret()
        self.update_version()

    def initialize(self):
        self.prepare_storage()
        self.db.execute('postgres', f"ALTER USER {DB_USER} WITH PASSWORD '{DB_PASSWORD}'")
        self.create_db()
        self.db.execute('postgres', f"GRANT CREATE ON SCHEMA public TO {DB_USER}")
        self.set_sync_secret()
        self.update_version()
        with open(self.install_file, 'w') as f:
            f.write('installed\n')
        
    def set_sync_secret(self):
        if not path.isfile(self.sync_secret_file):
            with open(self.sync_secret_file, 'w') as f:
                f.write(uuid.uuid4().hex)

    def create_db(self):
        self.db.create_db_if_missing('matrix')
        self.db.create_db_if_missing('sync')
        self.db.create_db_if_missing('whatsapp')
        self.db.create_db_if_missing('telegram')
        self.db.create_db_if_missing('signal')

    def update_version(self):
        shutil.copy(self.new_version, self.current_version)

    def clear_version(self):
        if os.path.exists(self.current_version):
            os.remove(self.current_version)

    def on_disk_change(self):
        self.prepare_storage()

    def prepare_storage(self):
        storage.init_storage(APP_NAME, USER_NAME)
        
    def on_domain_change(self):
        self.install_config()
        service.restart(SYSTEMD_NGINX)
        service.restart(SYSTEMD_MATRIX)

    def backup_pre_stop(self):
        self.pre_refresh()

    def restore_pre_start(self):
        self.post_refresh()

    def restore_post_start(self):
        self.configure()

    def fix_permissions(self):
        check_output('chown -R {0}.{0} {1}'.format(USER_NAME, self.common_dir), shell=True)
        check_output('chown -R {0}.{0} {1}/'.format(USER_NAME, self.data_dir), shell=True)
