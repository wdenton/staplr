#!/bin/sh

# Set up and configure everything necessary for
# Sonic Pi to run headless (on wdenton.uit.yorku.ca)

# The script takes one argument: the name of the composition to be used

if [ "$#" -ne 1 ]; then
    echo "Specify a composition"
    exit 1
fi
COMPOSITION=$1

cd ~/staplr/ || exit

# Is kernel module snd_aloop enabled?
lsmod | grep -q snd_aloop
if [ "$?" -ne 0 ] ; then
    echo "snd_aloop module must be enabled ... enabling"
    sudo modprobe snd-aloop
fi

tmux start-server

# tmux has-session -t staplr 2>/dev/null
# if [ "$?" -eq 1 ] ; then
#     echo "Session staplr exists; killing it"
#     echo "You may need to kill Sonic Pi manually and rerun everything"
#     tmux kill-session -t staplr
# fi

echo "Killing session staplr ..."
tmux kill-session -t staplr

echo "Making new session staplr ..."
tmux new-session -d -s "staplr"

echo "JACK ..."
tmux new-window -t staplr:2 -n "jack"
# tmux send-keys -t staplr:2 "cd ~/jack2/build/linux/; ./jackd -dalsa -dhw:0 -r44100 -p1024 -n2" "C-m"
tmux send-keys -t staplr:2 "jackd -dalsa -dhw:0 -r44100 -p1024 -n2" "C-m"
sleep 2

echo "Sonic Pi ... (then sleeping 20)"
tmux new-window -t staplr:3 -n "sonicpi"
# tmux send-keys -t staplr:3 "xvfb-run /usr/local/src/sonic-pi-2.6.0/bin/sonic-pi" "C-m"
tmux send-keys -t staplr:3 "xvfb-run sonic-pi" "C-m"
sleep 20

echo "DarkIce ..."
tmux new-window -t staplr:4 -n "darkice"
tmux send-keys -t staplr:4 "darkice -c darkice-wdenton.cfg" "C-m"
sleep 2

echo "Connecting SuperCollider and Darkice ..."
tmux send-keys -t staplr:1 "./connect-darkice.sh" "C-m"

echo "Starting composition $COMPOSITION ..."
tmux send-keys -t staplr:1 "cat $COMPOSITION | sonic_pi" "C-m"

echo "Tailing log ..."
tmux send-keys -t staplr:1 "tail -f ~/.sonic-pi/log/debug.log" "C-m"
tmux select-window -t 1
