from os.path import dirname, join
from syncloudlib.integration.conftest import *

DIR = dirname(__file__)


@pytest.fixture(scope="session")
def project_dir():
    return join(DIR, '..')


@pytest.fixture(scope="session")
def selenium_timeout():
    return 30