#!/bin/sh

# The last line of darkice's output will be
#   Registering as JACK client darkice-3712
# That number is its PID, so we need to know the PID to connect inputs
# and outputs
#
# ps makes this easy.  -C is "select by command name," -o pid says we only
# want to get that column, and the = suppresses the column heading
# (Annoyingly, on wdenton there is a space before the PID, so
# make sure to remove all whitespace.)
DARKICE_PID=`ps -C darkice -o pid= | sed 's/\s*//'`

jack_connect SuperCollider:out_1 darkice-${DARKICE_PID}:left && \
    jack_connect SuperCollider:out_2 darkice-${DARKICE_PID}:right ;
