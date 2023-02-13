# ConnectSSHTunnel
Connects your PC, Raspberry PI, OpenWRT router to an SSH tunnel and routes all traffic through it.

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
* Copy the correct badvpn binary or build your own. The target name MUST be `badvpn-tun2socks`. For OpenWRT (aarch64) on a Raspberry PI 4:
  ```bash
  cp badvpn_compiled/badvpn-tun2socks_openwrt_rpi4_aarch64 badvpn-tun2socks
  ```
* Install the dependencies (OpenWRT)
  ```bash
  opkg update
  opkg install coreutils-base64 procps-ng-pkill coreutils-dirname openvpn ncat openssh-client sshpass bash
  ```
* Run the script once to copy the config file. Then edit `config.sh`. DO NOT edit `default_config.sh`!
* Make sure, the certificate of the server you specified in config to connect is trusted. If you are not sure run this (replace the placeholders before!):
  ```bash
  ssh <user>@<server_ip> -p <server_port>
  ```
  If you are behind a proxy:
  ```bash
  ssh <user>@<server_ip> -p <server_port> -o "ProxyCommand=ncat --proxy-type http --proxy <proxy_ip>:<proxy_port> --proxy-auth <proxy_user>:<proxy_password> %h %p"
  ```
* Finally, the script can be started with
  ```bash
  ./connect_ssh_server.sh
  ```
  Note that the script must be run as root, so you may need to prefix the command above with `sudo`.
  If you want to start the script on boot, add this to `/etc/rc.local`, in the line before `exit`.
  ```bash
  /bin/bash /path/to/connect_ssh_server.sh &
  ```
