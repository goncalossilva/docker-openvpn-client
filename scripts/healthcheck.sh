#!/bin/sh

# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks.

ping -c 1 google.com
STATUS=$?

if [[ ${STATUS} -ne 0 ]]; then
    echo "Network is down"
    exit 1
fi

echo "Network is up"
exit 0
