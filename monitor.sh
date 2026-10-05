#!/bin/bash

# ------------------------------------------------------------
# B4-1 monitor.sh
# owner : agent-dev
# group : agent-core
# mode  : 750
# runner: agent-admin
# ------------------------------------------------------------

APP_NAME="agent-app-linux-x86"
PORT=15034
LOG_FILE="/var/log/agent-app/monitor.log"


# ------------------------------------------------------------
# 1. Health Check - Process
# ------------------------------------------------------------

if ! pgrep -f "$APP_NAME" > /dev/null; then
    echo "[ERROR] agent process not found"
    exit 1
fi


# ------------------------------------------------------------
# 2. Health Check - TCP Port
# ------------------------------------------------------------

if ! ss -lnt | grep -q ":${PORT}"; then
    echo "[ERROR] port ${PORT} is not listening"
    exit 1
fi


# ------------------------------------------------------------
# 3. Status Check - Firewall
#    Firewall inactive is WARNING, not fatal.
# ------------------------------------------------------------

if ! sudo /usr/sbin/ufw status | grep -q "Status: active"; then
    echo "[WARNING] firewall is inactive"
fi


# ------------------------------------------------------------
# 4. Resource Collection
# ------------------------------------------------------------

DISK_USED=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')

MEM=$(free | awk '/Mem:/ {
    printf "%.0f", $3/$2*100
}')

CPU=$(top -bn1 | awk '/Cpu\(s\)/ {
    printf "%.0f", 100 - $8
}')


# ------------------------------------------------------------
# 5. Resource Threshold
# ------------------------------------------------------------

if (( CPU > 20 )); then
    echo "[WARNING] high CPU usage: ${CPU}%"
fi

if (( MEM > 10 )); then
    echo "[WARNING] high memory usage: ${MEM}%"
fi

if (( DISK_USED > 80 )); then
    echo "[WARNING] high disk usage: ${DISK_USED}%"
fi


# ------------------------------------------------------------
# 6. Log Data
# ------------------------------------------------------------

PID=$(pgrep -n -f "$APP_NAME")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')


# ------------------------------------------------------------
# 7. Append Log
# ------------------------------------------------------------

echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK_USED}%" \
    >> "$LOG_FILE"
