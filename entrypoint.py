#!/usr/bin/env python3
import schedule
import sys
import time
import subprocess
from datetime import date


def runner():
    subprocess.run(['/usr/bin/env', 'bash', '/runner.sh'] + sys.argv[1:])
    next_run = schedule.next_run().strftime('%Y-%m-%d %H:%M:%S')
    print(f'Next run at [{next_run}]')

# setup jobs
schedule.every().week.do(runner)
# print all jobs
[print(f'JOB - {str(job)}') for job in schedule.jobs]
# run now
schedule.run_all()

while True:
    schedule.run_pending()
    time.sleep(1)