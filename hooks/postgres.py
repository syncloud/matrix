import shutil
from os.path import join, isfile, isdir
from subprocess import check_output, CalledProcessError

from syncloudlib import logger


class Database:

    def __init__(self, app_dir, data_dir, config_path, port, user):
        self.log = logger.get_logger('database')
        self.app_dir = app_dir
        self.config_path = config_path
        self.data_dir = data_dir
        self.postgresql_config = join(self.config_path, 'postgresql.conf')
        self.database_dir = join(self.data_dir, 'database')
        self.old_major_version_file = join(self.data_dir, 'db.major.version')
        self.new_major_version_file = join(self.app_dir, 'db.major.version')
        self.backup_file = join(self.data_dir, 'database.dump')
        self.database_host = '{0}:{1}'.format(self.database_dir, port)
        self.user = user

    def get_database_path(self):
        return self.database_dir

    def remove(self):
        if not isfile(self.backup_file):
            raise Exception("Backup file does not exist: {0}".format(self.backup_file))
    
        if isdir(self.database_dir):
            shutil.rmtree(self.database_dir)

    def init(self):
        self.run('{0}/bin/initdb.sh {1}'.format(self.app_dir, self.database_dir))

    def init_config(self):
        shutil.copy(self.postgresql_config, self.database_dir)

    def execute(self, database, sql):
        self.run('snap run matrix.psql -U {0} -d {1} -c "{2}"'.format(self.user, database, sql))

    def restore(self):
        self.run('snap run matrix.psql -f {0} postgres'.format(self.backup_file))

    def backup(self):
        self.run('snap run matrix.pgdumpall -f {0}'.format(self.backup_file))
        shutil.copy(self.new_major_version_file, self.old_major_version_file)

    def create_db_if_missing(self, db):
        try:
            self.execute(db, "select 1")
            self.log.info(f'database "{db}" already exists')
        except Exception:
            self.log.info(f'creating database: "{db}"')
            self.execute('postgres', self.user, f"CREATE DATABASE sync OWNER {self.user} TEMPLATE template0 ENCODING 'UTF8'")

    def run(self, cmd):
        try:
            self.log.info("postgres executing: {0}".format(cmd))
            output = check_output(cmd, shell=True).decode()
            self.log.info(output)
        except CalledProcessError as e:
            self.log.error("postgres error: " + e.output.decode())
            raise e
