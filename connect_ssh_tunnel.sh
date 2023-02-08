#!/bin/sh

# go in directory of script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

if [ ! -f "config.sh" ]; then
    cp default_config.sh config.sh
fi

# read config
# shellcheck source=/dev/null
. config.sh


# will get extracted out of route command later
GATEWAY=

# decode passwords
PROXY_PASS=$(echo "$PROXY_PASS" | base64 --decode)
SERVER_PASS=$(echo "$SERVER_PASS" | base64 --decode)

echo "$SERVER_PASS"

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
(./badvpn-tun2socks --tundev tun0 --netif-ipaddr 10.20.0.2 --netif-netmask 255.255.255.0 --socks-server-addr 127.0.0.1:1080 --udpgw-remote-server-addr 127.0.0.1:$BADVPN_UDPGW_PORT &) > /root/badvpn.log
sleep 1

# this part of the code is in a loop to allow automatic reconnects when the internet connection drops for whatever reason
while true
do
    # first do a cleanup without stopping badvpn
    cleanup false

    # then check if the proxy server is up
    ncat -w 1 -z 10.1.1.3 8080 &> /dev/null
    PROXY_CHECK=$?

    # get the gateway from the route command
    GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
    # make all traffic to the ssh server pass through the detected gateway
    route add $SERVER_DOMAIN gw $GATEWAY metric 5
    # the remaining traffic will go through the badvpn gateway and therefore through the ssh tunnel
    route add default gw 10.20.0.2 metric 6

    if [ "$PROXY_CHECK" -ne 0 ]
    then
        # if the proxy is not up, we can't connect using it
        echo "Connecting without using proxy..."
        sshpass -p $SERVER_PASS ssh -NTD 127.0.0.1:1080 $SERVER_USER@$SERVER_DOMAIN -p $SERVER_PORT -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval=2" -o "ServerAliveCountMax=2"
    else
        # the proxy responded to the ncat command, so we can use it
        echo "Connecting using proxy..."
        sshpass -p $SERVER_PASS ssh -NTD 127.0.0.1:1080 $SERVER_USER@$SERVER_DOMAIN -p $SERVER_PORT -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval=2" -o "ServerAliveCountMax=2" -o "ProxyCommand=ncat --proxy-type http --proxy ${PROXY_DOMAIN}:${PROXY_PORT} --proxy-auth ${PROXY_USER}:${PROXY_PASS} %h %p"
    fi

    # repeat all that after 5 seconds
    sleep 5
done
