import subprocess

print(subprocess.check_output('snap run matrix.storage-change', shell=True))
