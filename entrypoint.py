#!/usr/bin/env python3
import schedule
import sys
import time
import subprocess


def runner():
    subprocess.run(['/usr/bin/env', 'bash', '/runner.sh'])

# setup jobs
schedule.every().sunday.do(runner)
# print all jobs
[print(f'JOB - {str(job)}') for job in schedule.jobs]
# run now
schedule.run_all()

while True:
    schedule.run_pending()
    time.sleep(1)