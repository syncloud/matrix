import socket
import subprocess
import time
from contextlib import contextmanager


def free_port():
    with socket.socket() as probe:
        probe.bind(('127.0.0.1', 0))
        return probe.getsockname()[1]


@contextmanager
def forwarded(device_host, password, remote_socket):
    port = free_port()
    tunnel = subprocess.Popen([
        'sshpass', '-p', password, 'ssh', '-N',
        '-o', 'StrictHostKeyChecking=no', '-o', 'ExitOnForwardFailure=yes',
        '-L', '127.0.0.1:{0}:{1}'.format(port, remote_socket),
        'root@{0}'.format(device_host),
    ])
    try:
        for _ in range(50):
            if tunnel.poll() is not None:
                raise RuntimeError('ssh tunnel exited with {0}'.format(tunnel.returncode))
            try:
                socket.create_connection(('127.0.0.1', port), timeout=1).close()
                break
            except OSError:
                time.sleep(0.2)
        yield port
    finally:
        tunnel.terminate()
        tunnel.wait()


def exchange(port, payload):
    with socket.create_connection(('127.0.0.1', port), timeout=10) as conn:
        conn.sendall(b'PROXY TCP4 198.51.100.7 10.0.0.1 40000 443\r\n' + payload)
        reply = conn.recv(65536)
        conn.settimeout(2)
        while reply:
            try:
                chunk = conn.recv(65536)
            except socket.timeout:
                break
            if not chunk:
                break
            reply += chunk
        return reply
