#!/bin/bash
# Crontab setup:
#
# At reboot startup
# @reboot ~/brewpi-script/utils/updateCronCircus.sh start
#
# Every 10 minutes check if circus are running, if not start it up again
# */10 * * * * ~/brewpi-script/utils/updateCronCircus.sh startifstopped
#

# Path to circus config file
CONFIG=~/brewpi-django/circus.ini

# Config
CIRCUSD=~/venv/bin/circusd
CIRCUSCTL=~/venv/bin/circusctl
NAME="Brewpi-django supervisor: circusd: "
# Cron Regexp
REBOOT_ENTRY="^@reboot.*_updateCronCircus.sh start$"
CHECK_ENTRY="^\*/10 \* \* \* \*.*_updateCronCircus.sh startifstopped$"
# Cron Entries
REBOOT_CRON="@reboot ~/brewpi-django/brewpi-script/utils/_updateCronCircus.sh start"
CHECK_CRON="*/10 * * * * ~/brewpi-django/brewpi-script/utils/_updateCronCircus.sh startifstopped"

# Source in our virtualenv
if [ ! -f ~/venv/bin/activate ]; then
    echo "ERROR: Could not find python virtualenv enviroment"
    exit -1
fi

# Source or virtualenv
source ~/venv/bin/activate

start() {
    echo -n "Starting $NAME"
    $CIRCUSD --daemon $CONFIG
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        echo "done"
    else
        echo "failed, please see logfile."
    fi
}

stop() {
    echo -n "Stopping $NAME"
    $CIRCUSCTL quit
}

status() {
    $CIRCUSCTL status
}

startifstopped() {
    $CIRCUSCTL status >/dev/null 2>&1
    RETVAL=$?
    if [ ! $RETVAL -eq 0 ]; then
        start
    fi
}

add2cron() {
    echo "Checking and fixing cron entries for brewpi-django."
    if ! crontab -l|grep -E -q "$REBOOT_ENTRY"; then
        (crontab -l; echo "$REBOOT_CRON" ) | crontab -
        echo " - Adding @reboot cron entry for brewpi-django to cron"
    fi
    if ! crontab -l|grep -E -q "$CHECK_ENTRY"; then
        (crontab -l; echo "$CHECK_CRON" ) | crontab -
        echo " - Adding periodic checks for brewpi-django to cron"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    startifstopped)
        startifstopped
        ;;
    fixcron)
        fixcron
        ;;
    *)
        echo "Usage: $0 {start|stop|status|startifstopped|add2cron}"
        exit 0
        ;;
esac