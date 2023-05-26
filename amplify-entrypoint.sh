#!/bin/bash
set -e
# Start amplify-agent as root
service amplify-agent start
# Switch to the non-root user and delegate to the original entrypoint script
exec gosu 1001 /opt/bitnami/scripts/nginx/entrypoint.sh "$@"
