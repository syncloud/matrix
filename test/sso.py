from urllib.parse import parse_qs, urljoin, urlparse

import requests

REDIRECTS = (301, 302, 303, 307, 308)


def sso_login(app_domain, auth_domain, user, password):
    session = requests.session()
    session.verify = False
    first = session.post('https://{0}/api/firstfactor'.format(auth_domain), timeout=60, json={
        'username': user,
        'password': password,
        'keepMeLoggedIn': False,
        'requestMethod': 'GET',
        'targetURL': 'https://{0}/'.format(app_domain),
    })
    assert first.status_code == 200, first.text

    url = 'https://{0}/_matrix/client/v3/login/sso/redirect?redirectUrl=https://{0}/'.format(app_domain)
    login_token = None
    for _ in range(10):
        response = session.get(url, allow_redirects=False, timeout=60)
        assert response.status_code in REDIRECTS, '{0} {1}: {2}'.format(url, response.status_code, response.text[:500])
        url = urljoin(url, response.headers['Location'])
        login_token = parse_qs(urlparse(url).query).get('loginToken', [None])[0]
        if login_token:
            break
    assert login_token, url

    login = session.post('https://{0}/_matrix/client/v3/login'.format(app_domain), timeout=60,
                         json={'type': 'm.login.token', 'token': login_token})
    assert login.status_code == 200, login.text
    return login.json()


def password_login(app_domain, user, password):
    return requests.post('https://{0}/_matrix/client/v3/login'.format(app_domain), verify=False, json={
        'type': 'm.login.password',
        'identifier': {'type': 'm.id.user', 'user': user},
        'password': password,
    })


def is_admin(app_domain, token):
    alias = requests.get('https://{0}/_matrix/client/v3/directory/room/%23admins:{0}'.format(app_domain), verify=False)
    assert alias.status_code == 200, alias.text
    joined = requests.get('https://{0}/_matrix/client/v3/joined_rooms'.format(app_domain), verify=False,
                          headers={'Authorization': 'Bearer ' + token})
    assert joined.status_code == 200, joined.text
    return alias.json()['room_id'] in joined.json()['joined_rooms']
