#!/bin/bash
set -e
echo "Starting rake task..." >> $LOG_DIR/rake.log
source /var/www/manual_providers/release/config/.env

rbenv rehash

cd /var/www/manual_providers/release/
bundle exec rake cronjobs:se_manual_providers_report --trace 2>&1 >> $LOG_DIR/cronjob.log

curl -d "m=Ran ManualProviders cronjob" "https://nosnch.in/021558153c"

date > $LOG_DIR/cron_last_run_at
