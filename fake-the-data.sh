#!/bin/sh

for I in `seq -w 1 60`
do
    echo -n "$I\r"
    cp data/test/structured/S-${I}.json data/live/activity.json
    sleep 60
done
