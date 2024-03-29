#!/bin/bash

# these are example servers for different ssh services
# this is only required when using connect_ssh_tunnel.sh

# ServerSSH: https://serverssh.net/?q=create-ssh&filter=29 (VPS Provider: OVH)
#SERVER_DOMAIN=ge.serverssh.net
#SERVER_PORT=888
#BADVPN_UDPGW_PORT=7200

# JagoanSSH: https://www.jagoanssh.com/?do=create-account&filter=215 (VPS Provider: OVH)
#SERVER_DOMAIN=ge.ipservers.xyz
#SERVER_PORT=888
#BADVPN_UDPGW_PORT=7200

# VPN Jantit: https://www.vpnjantit.com/create-free-account?server=gr5&type=SSH (VPS Provider: gr1, gr2, gr3: OVH; gr4, gr5: 1&1 IONOS, gr6: myLoc)
SERVER_DOMAIN=gr5.vpnjantit.com
SERVER_PORT=80
BADVPN_UDPGW_PORT=7200


# the credentials for the ssh server
# this is only required when using connect_ssh_tunnel.sh
SERVER_USER=sshuser
# base64 encoded password for the ssh server
# this is only required when using connect_ssh_tunnel.sh
SERVER_PASS=

# the ip/domain of the proxy server
# this is always required
PROXY_DOMAIN=some.proxy.server
# the port of the proxy server
# this is always required
PROXY_PORT=8080
# the user for an authenticated proxy
# if you dont need credentials, leave this empty
PROXY_USER=proxyuser
# the base64 encoded password for the proxy
# if you dont need credentials, leave this empty
PROXY_PASS=
