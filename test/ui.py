import traceback

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


def dismiss_modals(selenium):
    xpaths = [
        "//*[contains(@class,'mx_Toast')]//button[normalize-space(.)='Dismiss']",
        "//div[contains(@class,'mx_Dialog')]//button[normalize-space(.)='Yes, dismiss']",
        "//div[@role='dialog']//button[normalize-space(.)='Ok']",
    ]
    for _ in range(8):
        target = None
        for xp in xpaths:
            found = [b for b in selenium.driver.find_elements(By.XPATH, xp) if b.is_displayed()]
            if found:
                target = found[0]
                break
        if target is None:
            break
        try:
            selenium.driver.execute_script("arguments[0].click()", target)
            time.sleep(1)
        except Exception:
            break


def compose_menu(selenium, item):
    item_xpath = "//button[normalize-space(.)='{0}']".format(item)
    compose_xpath = "//button[@aria-labelledby=//span[normalize-space(.)='New conversation']/@id]"
    for _ in range(6):
        dismiss_modals(selenium)
        try:
            selenium.find_by_xpath(compose_xpath).click()
        except Exception:
            continue
        time.sleep(1)
        dismiss_modals(selenium)
        buttons = [b for b in selenium.driver.find_elements(By.XPATH, item_xpath) if b.is_displayed()]
        if buttons:
            try:
                buttons[0].click()
                return
            except Exception:
                continue
    raise Exception("compose menu item not found: " + item)


def test_login(selenium, device_user, device_password):
    selenium.open_app()
    selenium.find_by_xpath("//a[text()='Sign in']").click()
    selenium.find_by_id("mx_LoginForm_username").send_keys(device_user)
    password = selenium.find_by_id("mx_LoginForm_password")
    password.send_keys(device_password)
    selenium.screenshot('login')
    password.send_keys(Keys.RETURN)
    selenium.find_by_xpath("//h1[contains(.,'Welcome user')]")
    dismiss_modals(selenium)
    selenium.screenshot('main')


def test_room(selenium, device_user, device_password):
    dismiss_modals(selenium)
    compose_menu(selenium, "New room")
    label = selenium.find_by_xpath("//label[normalize-space(.)='Name']")
    name = selenium.driver.find_element(By.ID, label.get_attribute('for'))
    name.send_keys("testroom")
    selenium.find_by_xpath("//button[text()='Create room']").click()
    selenium.screenshot('room')


def test_message(selenium, device_user, device_password):
    dismiss_modals(selenium)
    selenium.find_by_xpath("//*[@data-testid='room-list']//*[@title='testroom']").click()
    name = selenium.find_by_xpath("//*[@aria-label='Message composer']//div[@role='textbox']")
    name.send_keys("test message")
    name.send_keys(Keys.RETURN)
    dismiss_modals(selenium)
    selenium.screenshot('message')


def test_image(selenium, device_user, device_password):
    dismiss_modals(selenium)
    file = selenium.driver.find_element(By.XPATH, "//input[@type='file' and @multiple]")
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    selenium.screenshot('image-before-send')
    file.send_keys(join(DIR, 'images', 'profile.jpeg'))
    selenium.find_by_xpath("//button[text()='Upload']").click()
    assert not selenium.exists_by(By.XPATH, "//h2[contains(.,'Upload Failed')]")
    selenium.screenshot('image')


def test_image_big(selenium, device_user, device_password):
    file = selenium.driver.find_element(By.XPATH, "//input[@type='file' and @multiple]")
    selenium.driver.execute_script("arguments[0].removeAttribute('style')", file)
    image = join(DIR, 'images', 'image-big.png')
    file.send_keys(image)
    selenium.find_by_xpath("//button[text()='Upload']").click()
    assert not selenium.exists_by(By.XPATH, "//h2[contains(.,'Upload Failed')]")
    selenium.screenshot('image-big')


@pytest.mark.parametrize("bridge", ["whatsapp", "telegram", "signal", "slack", "discord"])
def test_bridge_bot(selenium, app_domain, bridge):
    attempt = 0
    attempts = 10
    while True:
        try:
            bridge_bot(bridge, selenium, app_domain, attempt)
            break
        except Exception as e:
            selenium.screenshot('{0}-bot-error-{1}'.format(bridge, attempt))
            attempt += 1
            if attempt > attempts:
                raise e
            else:
                print(traceback.format_exc())
                time.sleep(5)


def bridge_bot(bridge, selenium, app_domain, attempt):
    if selenium.driver.find_elements(By.XPATH, "//div[contains(@class,'mx_Dialog')]"):
        from selenium.webdriver.common.action_chains import ActionChains
        ActionChains(selenium.driver).send_keys(Keys.ESCAPE).perform()
        time.sleep(1)
    compose_menu(selenium, "Start chat")
    bot = '@{0}bot:{1}'.format(bridge, app_domain)
    invite = selenium.find_by_xpath("//*[contains(@class,'mx_InviteDialog')]//input")
    invite.send_keys(bot)
    invite.send_keys(Keys.RETURN)
    selenium.screenshot('{0}-bot-invite-{1}'.format(bridge, attempt))
    selenium.find_by_xpath("//*[contains(@class,'mx_InviteDialog_goButton')]").click()
    time.sleep(5)
    for label in ["Continue", "Start chat", "Yes"]:
        button = selenium.driver.find_elements(By.XPATH, "//button[text()='{0}']".format(label))
        if button:
            button[0].click()
            time.sleep(2)
    dismiss_modals(selenium)
    name = selenium.find_by_xpath("//*[@aria-label='Message composer']//div[@role='textbox']")
    name.send_keys("help")
    selenium.screenshot('{0}-bot-help-{1}'.format(bridge, attempt))
    name.send_keys(Keys.RETURN)
    selenium.screenshot('{0}-bot-help-sent-{1}'.format(bridge, attempt))
    selenium.find_by_xpath("//h4[text()='Administration']")
    selenium.screenshot('{0}-bot-answer-{1}'.format(bridge, attempt))

