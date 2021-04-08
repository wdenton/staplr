#!/bin/bash

# If STAPLR jams then it needs to be restarted. Put this in the
# crontab and run it every two minutes to keep an eye on things.
#
# */2 * * * * ~/src/staplr/is-staplr-jammed.sh

logs="${HOME}/.sonic-pi/log"
debug_log="${logs}/debug.log"
errors_log="${logs}/server-errors.log"

# This reports the last modification time in seconds since epoch (01 Jan 1970 00:00)
last_modified=$(stat --format "%X" ${debug_log})

# And this is the current seconds since epoch.
seconds_since_epoch=$(date "+%s")

let diff=${seconds_since_epoch}-${last_modified}

# It should update every minute, so if it's over 120 seconds since it was
# changed, there's a problem.
trouble_seconds=120

if [[ $diff -gt $trouble_seconds ]]
then
    echo "STAPLR jammed about $diff seconds ago!  Restarting."
    cp -p ${errors_log} ${errors_log}.${last_modified}
    ${HOME}/src/staplr/setup-staplr.sh ${HOME}/src/staplr/compositions/current.spi
fi
