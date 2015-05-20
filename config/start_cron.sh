#!/bin/bash
/usr/bin/printenv | sed -r 's/^([^=]+)=(.*?)/export \1="\2"/' > /var/www/manual_providers/release/config/.env
exec /usr/sbin/cron -f
