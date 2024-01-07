# ConnectSSHTunnel
Connects your PC, Raspberry PI, OpenWRT router to an SSH tunnel and routes all traffic through it.<br>
Also has simple proxy connect script to just route all traffic through the proxy (tun2http) without using SSH tunnel and server.

## Features
* Auto reconnect if SSH/proxy connection drops
* Auto detect gateway (router)
* Revert changes on exit (CTRL+C)
* authenticated HTTP Proxy support

## Install (on Raspberry PI 4 with [OpenWRT](https://openwrt.org)/[ImmortalWRT](https://immortalwrt.org))
Currently, this install procedure is only tested on OpenWRT/ImmortalWRT on a Raspberry PI 4 and Ubuntu 22.04.3 LTS.<br>
You need access to the internet to perform the installation steps.

* Install the dependencies
  * OpenWRT/ImmortalWRT:
    ```bash
    opkg update
    opkg install coreutils-base64 procps-ng-pkill coreutils-dirname openvpn ncat openssh-client sshpass bash
    ```
    You also need to install [GOST](https://gost.run/en/) for the proxy_connect.sh script.<br>
    If you are using ImmortalWRT, then you can also install it by using the following command:
    ```bash
    opkg install gost
    ```
  * Ubuntu:
    ```bash
    apt install coreutils procps openvpn ncat openssh-client sshpass bash
    ```

* If you are using OpenWRT/ImmortalWRT, make sure that the gateway metric of your WAN interface is set to 600. You can find this setting under
  ```
  Network->Interfaces->Edit button on your WAN interface->Advanced Settings->Use gateway metric
  ```

* Clone this repository
  ```bash
  git clone https://github.com/PocketMiner82/ConnectSSHTunnel.git
  cd ConnectSSHTunnel
  ```

* Copy the correct badvpn binary or build your own. The target name MUST be `badvpn-tun2socks`. For OpenWRT/ImmortalWRT (aarch64) on a Raspberry PI 4:
  ```bash
  cp badvpn_compiled/badvpn-tun2socks_openwrt_rpi4_aarch64 badvpn-tun2socks
  ```

* Run the script once to copy the config file. Then edit `config.sh`. DO NOT edit `default_config.sh`!

* For SSH Tunnel: Make sure, the certificate of the server you specified in config to connect is trusted. If you are not sure run this (replace the placeholders before!):
  ```bash
  ssh <user>@<server_ip> -p <server_port>
  ```
  If you are behind a proxy:
  ```bash
  ssh <user>@<server_ip> -p <server_port> -o "ProxyCommand=ncat --proxy-type http --proxy <proxy_ip>:<proxy_port> --proxy-auth <proxy_user>:<proxy_password> %h %p"
  ```

* Finally, the script can be started:
  ```bash
  ./connect_ssh_server.sh
  ```
  Or for proxy_connect.sh:
  ```bash
  ./proxy_connect.sh
  ```
  Note that the script must be run as root, so you may need to prefix the command above with `sudo`.
* If you want to start the script on boot, add this to `/etc/rc.local`, in the line before `exit`. This may only work on OpenWRT/ImmortalWRT.
  ```bash
  /bin/bash /path/to/connect_ssh_server.sh &
  ```
  Or for proxy_connect.sh:
  ```bash
  /bin/bash /path/to/proxy_connect.sh &
  ```
