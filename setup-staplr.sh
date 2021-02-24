#!/bin/bash

##
## STAPLR setup
##

# Set up and configure everything necessary for Sonic Pi to run
# headless, play a composition from a script, and stream the output
# to DarkIce so it can be broadast.

# The script takes one argument: the name of the composition to be used

if [ "$#" -ne 1 ]; then
    echo "Specify a composition"
    exit 1
fi
COMPOSITION=$1

cd ~/src/staplr/ || exit

##
## Kernel module snd_aloop
##

# This needs to be enabled.  Once that's done, it won't go away,
# but it needs to be checked.
if ! lsmod | grep -q snd_aloop
then
    echo "snd_aloop module not enabled ... enabling"
    sudo modprobe snd-aloop
fi

##
## tmux
##

# The whole thing depends on tmux.  Start a server if one isn't
# already running.
tmux start-server

# If a STAPLR tmux session is already running, then we want to kill
# it. But we can't just kill each window, because that will leaves
# daemons and other processes running. We need to hit Ctrl-c in each
# window to stop whatever is running, and then we can kill the window.
#
# Worst comes to worst, run
# $ tmux attach -t staplr
# and kill everything by hand.

# By the way, I don't know why a ! isn't needed in this if, since it
# returns 0 if the session exists. This reads cleanly, but it doesn't
# seem to work the Unix way.
#
# I used to have this:
#
# tmux has-session -t staplr 2>/dev/null
# if [ "$?" -eq 0 ] ; then
#
# But shellcheck didn't like that.

if tmux has-session -t staplr
then
    echo "Session staplr exists; killing it ..."
    tmux send-keys -t staplr:4 "C-c"
    tmux kill-window -t staplr:4
    sleep 1
    tmux send-keys -t staplr:3 "C-c"
    tmux kill-window -t staplr:3
    sleep 1
    tmux send-keys -t staplr:2 "C-c"
    tmux kill-window -t staplr:2
    sleep 1
    tmux send-keys -t staplr:1 "C-c"
    tmux kill-window -t staplr:1
    sleep 1
fi

echo "Making new session staplr ..."
tmux new-session -d -s "staplr"

##
## JACK
##

echo "JACK ..."
tmux new-window -t staplr:2 -n "jack"
# Use dbus-launch so it can be run without any X display variables being set,
# which means it can be called from cron.
# Otherwise, you get this error: "Unable to autolaunch a dbus-daemon without a $DISPLAY for X11."
# If X variables are set (i.e. you sshed in from an X session) it doesn't hurt anything.
tmux send-keys -t staplr:2 "dbus-launch jackd -dalsa -dhw:0 -r44100 -p1024 -n2" "C-m"
sleep 2

##
## Sonic Pi
##

echo "Sonic Pi ... (then sleeping 30) ..."
tmux new-window -t staplr:3 -n "sonic-pi"
tmux send-keys -t staplr:3 "xvfb-run sonic-pi" "C-m"
sleep 30

##
## DarkIce
##

echo "DarkIce ..."
tmux new-window -t staplr:4 -n "darkice"
tmux send-keys -t staplr:4 "darkice -c darkice/wdenton2.cfg" "C-m"
sleep 2

echo "Connecting SuperCollider and Darkice ..."
tmux send-keys -t staplr:1 "darkice/connect.sh" "C-m"

##
## Play the composition
##

echo "Playing $COMPOSITION ..."
tmux send-keys -t staplr:1 "cat $COMPOSITION | sonic_pi" "C-m"

##
## Leave things tidy
##

echo "Tailing log ..."
tmux send-keys -t staplr:1 "tail -f ~/.sonic-pi/log/debug.log" "C-m"
tmux select-window -t 1

# Now everything is left so that
# $ tmux attach -t staplr
# show the log tail.
