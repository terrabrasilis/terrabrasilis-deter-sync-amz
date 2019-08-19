#!/bin/bash
# start nginx in foreground
nginx -g 'daemon off;' &

# run cron in foreground
cron -f