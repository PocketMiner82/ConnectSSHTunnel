#!/bin/bash

# go in directory of script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

if [ ! -f "config.sh" ]; then
    cp default_config.sh config.sh
    echo "Copied config file. Please edit it, then re-run this script."
    exit
fi

# read config
# shellcheck source=/dev/null
. config.sh


# will get extracted out of route command later
GATEWAY=

# decode passwords
PROXY_PASS=$(echo "$PROXY_PASS" | base64 --decode)
SERVER_PASS=$(echo "$SERVER_PASS" | base64 --decode)

# undo all changes this script did
cleanup() {
    # param to tell if the badvpn service should also get stopped
    _stopBadvpn="${1:-true}";

    echo -e "\nCleanup...";

    # kill the processes
    if [ "$_stopBadvpn" = "true" ];
    then
        pkill -x badvpn-tun2sock;
    fi;
    pkill -x ssh;

    # remove the created routes
    route del $SERVER_DOMAIN gw ${GATEWAY:-localhost} metric 5;
    route del default gw 10.20.0.2 metric 6;
}

# called when the script receives an exit signal
onExit() {
    cleanup;
    exit;
}

# register a listener for when this script ends or the user pressed CTRL+C
trap onExit 1 2 3 15

# create the virtual tunnel device
openvpn --mktun --dev tun0
# and configure its ip
ifconfig tun0 10.20.0.1 netmask 255.255.255.0

# use badvpn to route the traffic coming from the SOCKS Proxy, OpenSSH will start to the tun0 device
# badvpn will also make sure, that UDP packets will get sent through the SSH tunnel
(./badvpn-tun2socks --tundev tun0 --netif-ipaddr 10.20.0.2 --netif-netmask 255.255.255.0 --socks-server-addr 127.0.0.1:1080 &) > /dev/null
sleep 1

# this part of the code is in a loop to allow automatic reconnects when the internet connection drops for whatever reason
while true
do
    # first do a cleanup without stopping badvpn
    cleanup false

    # get the gateway from the route command
    GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
    # make all traffic to the ssh server pass through the detected gateway
    route add $SERVER_DOMAIN gw $GATEWAY metric 5
    # the remaining traffic will go through the badvpn gateway and therefore through the ssh tunnel
    route add default gw 10.20.0.2 metric 6

    echo "Starting GOST..."
    gost -L socks5://:1080 -F http://$PROXY_USER:$PROXY_PASS@$PROXY_DOMAIN:$PROXY_PORT

    # repeat all that after 5 seconds
    sleep 5
done
