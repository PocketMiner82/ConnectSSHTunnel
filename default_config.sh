#!/bin/sh

# these are example servers for different ssh services

# ServerSSH: https://serverssh.net/?q=create-ssh&filter=29
#SERVER_DOMAIN=ge.serverssh.net
#SERVER_PORT=888
#BADVPN_UDPGW_PORT=7200

# JagoanSSH: https://www.jagoanssh.com/?do=create-account&filter=215
SERVER_DOMAIN=ge.ipservers.xyz
SERVER_PORT=888
BADVPN_UDPGW_PORT=7200


# the credentials for the ssh server
SERVER_USER=
# base64 encoded password for the ssh server
SERVER_PASS=

# the ip/domain of the proxy server
PROXY_DOMAIN=some.proxy.server
# the port of the proxy server
PROXY_PORT=8080
# the user for an authenticated proxy
PROXY_USER=your.user
# the base64 encoded password for the proxy
PROXY_PASS=