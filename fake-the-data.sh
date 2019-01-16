#!/bin/sh

for I in `seq -w 1 60`
do
    echo -n "$I\r"
    cp test-data/structured/S-${I}.json staplr-branch-activity-01.json
    sleep 60
done
