#!/bin/sh

################################################################################

echo "[INFO] Stopping tinyproxy"

killall -s SINGINT tinyproxy
sleep 5
killall -s SIGKILL tinyproxy
