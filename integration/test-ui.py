import pytest
import time
from os.path import dirname, join
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
        check_output('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias(app, device_host, domain)


def test_login(selenium, device_user, device_password):
    selenium.open_app()
    selenium.find_by_xpath("//div[text()='Sign In']").click()
    selenium.find_by_id("mx_LoginForm_username").send_keys(device_user)
    password = selenium.find_by_id("mx_LoginForm_password")
    password.send_keys(device_password)
    selenium.screenshot('login')
    password.send_keys(Keys.RETURN)
    selenium.find_by_xpath("//span[contains(.,'Welcome user')]")
    selenium.screenshot('main')


def test_room(selenium, device_user, device_password):
    selenium.find_by_xpath("//div[text()='Dismiss']").click()
    selenium.find_by_xpath("//div[@aria-label='Add room']").click()
    selenium.find_by_xpath("//div[@aria-label='New room']").click()
    name = selenium.find_by_xpath("//input[@label='Name']")
    name.send_keys("testroom")
    selenium.find_by_xpath("//button[text()='Create room']").click()
    selenium.screenshot('room')


def test_message(selenium, device_user, device_password):
    selenium.find_by_xpath("//div[@title='testroom']").click()
    name = selenium.find_by_xpath("//div[contains(@aria-label, 'Send an encrypted message')]")
    name.send_keys("test message")
    selenium.find_by_xpath("//div[@aria-label='Send message']").click()
    selenium.find_by_xpath("//div[text()='Later']").click()
    selenium.screenshot('message')


def test_image(selenium, device_user, device_password):
    file = selenium.driver.find_element(By.XPATH, "//div[@aria-label='Attachment']/../input[@type='file']")
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    file.send_keys(join(DIR, 'images', 'profile.jpeg'))
    selenium.find_by_xpath("//button[text()='Upload']").click()
    assert not selenium.exists_by(By.XPATH, "//h2[contains(.,'Upload Failed')]")
    selenium.screenshot('image')


def test_image_big(selenium, device_user, device_password):
    file = selenium.driver.find_element(By.XPATH, "//div[@aria-label='Attachment']/../input[@type='file']")
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    image = join(DIR, 'images', 'image-big.png')
    file.send_keys(image)
    selenium.find_by_xpath("//button[text()='Upload']").click()
    assert not selenium.exists_by(By.XPATH, "//h2[contains(.,'Upload Failed')]")
    selenium.screenshot('image-big')


@pytest.mark.parametrize("bridge", ["whatsapp", "telegram"])
def test_bridge_bot(selenium, app_domain, bridge):
    attempt = 0
    attempts = 20
    while True:
        try:
            bridge_bot(bridge, selenium, app_domain, attempt)
            break
        except Exception as e:
            selenium.screenshot('{0}-bot-error-{1}'.format(bridge, attempt))
            attempt += 1
            if attempt > attempts:
                raise e


def bridge_bot(bridge, selenium, app_domain, attempt):
    selenium.find_by_xpath("//div[@aria-label='Add']").click()
    selenium.find_by_xpath("//div[@aria-label='Start new chat']").click()
    bot = '@{0}bot:{1}'.format(bridge, app_domain)
    selenium.find_by_xpath("//input[@data-testid='invite-dialog-input']").send_keys(bot)
    selenium.screenshot('{0}-bot-invite-{1}'.format(bridge, attempt))
    selenium.find_by_xpath("//div[text()='Go']").click()
    time.sleep(5)
    name = selenium.find_by_xpath("//div[contains(@aria-label, 'Send a message')]")
    name.send_keys("help")
    selenium.screenshot('{0}-bot-help-{1}'.format(bridge, attempt))
    selenium.find_by_xpath("//div[@aria-label='Send message']").click()
    selenium.screenshot('{0}-bot-help-sent-{1}'.format(bridge, attempt))
    selenium.find_by_xpath("//h4[text()='Administration']")
    selenium.screenshot('{0}-bot-answer-{1}'.format(bridge, attempt))


def test_teardown(driver):
    driver.quit()

