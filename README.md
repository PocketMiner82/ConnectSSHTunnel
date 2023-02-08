# ConnectSSHTunnel
Connects your PC, Raspberry PI, OpenWRT router to an SSH tunnel and routes all traffic trough it.

## Features
* Auto reconnect if SSH connection drops
* Auto detect gateway (router)
* Revert changes on exit (CTRL+C)
* authenticated HTTP Proxy support

## Install
* Clone this repository
  ```bash
  git clone https://github.com/PocketMiner82/ConnectSSHTunnel.git
  cd ConnectSSHTunnel
  ```
* Copy the correct badvpn binary or build your own. e.g. The target name MUST be `badvpn-tun2socks`. For OpenWRT (aarch64) on a Raspberry PI 4:
  ```bash
  cp badvpn_compiled/badvpn-tun2socks_openwrt_rpi4_aarch64 ../badvpn-tun2socks
  ```
* Install the dependencies (OpenWRT)
  ```bash
  opkg update
  opkg install coreutils-base64 procps-ng-pkill coreutils-dirname openvpn ncat openssh-client sshpass
  ```
* Make sure, the certificate of the server you specified in config to connect is trusted. If you are not sure run this (replace the placeholders before!):
  ```bash
  ssh <user>@<server_ip> -p <server_port>
  ```
  If you are behind a proxy:
  ```bash
  ssh <user>@<server_ip> -p <server_port> -o "ProxyCommand=ncat --proxy-type http --proxy <proxy_ip>:<proxy_port> --proxy-auth <proxy_user>:<proxy_password> %h %p"
  ```