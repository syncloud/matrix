import subprocess

print(subprocess.check_output('snap run matrix.access-change', shell=True))

