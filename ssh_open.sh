#!/bin/bash

# go in directory of script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

# read config
# shellcheck source=/dev/null
. config.sh

SERVER_PORT=$1
SERVER_USER=$2

# decode password
PROXY_PASS=$(echo "$PROXY_PASS" | base64 --decode)

# check if we need to use a proxy
ncat -w 1 -z $PROXY_DOMAIN $PROXY_PORT &> /dev/null
PROXY_CHECK=$?

if [ "$PROXY_CHECK" -ne 0 ]
then
    # if the proxy is not up, we can't connect using it
    echo "Connecting without using proxy..."
    ssh $SERVER_USER@$SERVER_DOMAIN -p $SERVER_PORT
else
    # the proxy responded to the ncat command, so we can use it
    echo "Connecting using proxy..."
    ssh $SERVER_USER@$SERVER_DOMAIN -p $SERVER_PORT -o "ProxyCommand=ncat --proxy-type http --proxy ${PROXY_DOMAIN}:${PROXY_PORT} --proxy-auth ${PROXY_USER}:${PROXY_PASS} %h %p"
fi
