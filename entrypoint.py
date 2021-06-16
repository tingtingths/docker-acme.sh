#!/usr/bin/env python3
import schedule
import sys
import time
import subprocess
from datetime import date, datetime


last_run = None

def runner():
    global last_run
    subprocess.run(['/usr/bin/env', 'bash', '/runner.sh'] + sys.argv[1:])
    last_run = datetime.now()

# setup jobs
schedule.every().day.do(runner)
# print all jobs
[print(f'JOB - {str(job)}') for job in schedule.jobs]
# run now
schedule.run_all()

while True:
    schedule.run_pending()
    if last_run is not None:
        next_run = schedule.next_run().strftime('%Y-%m-%d %H:%M:%S')
        print(f'Next run at [{next_run}]')
        last_run = None
    time.sleep(1)
