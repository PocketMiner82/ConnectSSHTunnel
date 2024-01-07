# ConnectSSHTunnel
Connects your PC, Raspberry Pi, OpenWRT router to an SSH tunnel and routes all traffic through it.<br>
Also has simple proxy connect script to just route all traffic through the proxy (tun2http) without using SSH tunnel and server.

## Features
* Auto reconnect if SSH/proxy connection drops
* Auto detect gateway (router)
* Revert changes on exit (CTRL+C)
* authenticated HTTP Proxy support

## Install (on Raspberry Pi 4 with [OpenWRT](https://openwrt.org)/[ImmortalWRT](https://immortalwrt.org))
Currently, this install procedure is only tested on OpenWRT/ImmortalWRT on a Raspberry Pi 4 and Ubuntu 22.04.3 LTS.<br>
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

* Copy the correct badvpn binary or build your own. The target name MUST be `badvpn-tun2socks`. For OpenWRT/ImmortalWRT (aarch64) on a Raspberry Pi 4:
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

## Example: Use a Raspberry Pi 4 as an access point that automatically routes all traffic through an HTTP proxy or an SSH tunnel
* **Warning! This is meant to be used only in the local area network and not as a "real" router that is directly connected to the internet. Use with care!**
* [Download](https://firmware-selector.immortalwrt.org/?target=bcm27xx%2Fbcm2711&id=rpi-4) a FACTORY image of ImmortalWRT
* Use a tool like the [Raspberry Pi Imager](https://github.com/raspberrypi/rpi-imager) to flash the image to a USB Stick
* Open the cmdline.txt file in the boot partition of the stick and change the `root=/dev/mmcblk0p2` to `root=/dev/sda2`
* (If you run out of space later on, you may want to increase the ext4 partition (the second partition) that was created by the installer on the stick to fill the whole stick using a tool like [GParted](https://gparted.org/))
* Plug the stick in the Raspberry Pi, connect an ethernet cable to your computer and the Pi's LAN port
* Change your computer's settings to use a static IP instead of DHCP. Use `192.168.1.5` as your IP, `192.168.1.1` as the gateway (and DNS) and `255.255.255.0` or `/24` as the netmask.
* Then connect to the Pi:
  ```bash
  ssh root@192.168.1.1
  ```
  Accept the certificate.
* Run the command `passwd` to set a password for the root user (and the webinterface)
* After that, run the following commands:
  ```bash
  # /etc/config/dhcp
  uci del dhcp.lan
  # /etc/config/firewall
  uci del firewall.cfg02dc81.network
  uci del firewall.cfg03dc81.network
  uci add_list firewall.cfg03dc81.network='wan'
  uci add_list firewall.cfg03dc81.network='wan6'
  uci add firewall rule # =cfg0e92bd
  uci set firewall.@rule[-1].name='Allow LuCI'
  uci set firewall.@rule[-1].src='wan'
  uci set firewall.@rule[-1].dest_port='80'
  uci set firewall.@rule[-1].target='ACCEPT'
  uci add firewall rule # =cfg0f92bd
  uci set firewall.@rule[-1].name='Allow SSH'
  uci set firewall.@rule[-1].src='wan'
  uci set firewall.@rule[-1].dest_port='22'
  uci set firewall.@rule[-1].target='ACCEPT'
  # /etc/config/network
  uci del network.lan
  uci set network.wan=interface
  uci set network.wan.proto='dhcp'
  uci set network.wan.device='eth0'
  uci set network.wan.metric='600'
  # /etc/config/wireless
  uci del wireless.default_radio0.network
  uci commit
  ```
* Then `shutdown now`, disconnect the power, connect the ethernet cable to a router that provides internet, reconnect the power
* Go to `System->Administration->SSH Access` and enable `Gateway Ports`.
* Then connect to the Pi again:
  ```bash
  ssh root@immortalwrt
  ```
* Run the following commands to get the internal wifi working in AP mode<br>
  This is an example config for enabeling the 5 GHz Band in Germany, with the SSID "WLAN-Schnell" and the password "00000000". You should change those values!
  ```bash
  # /etc/config/dhcp
  uci set dhcp.lan=dhcp
  uci set dhcp.lan.interface='lan'
  uci set dhcp.lan.start='100'
  uci set dhcp.lan.limit='150'
  uci set dhcp.lan.leasetime='12h'
  uci set dhcp.lan.start='10'
  uci set dhcp.lan.limit='240'
  # /etc/config/firewall
  uci add_list firewall.cfg02dc81.network='lan'
  # /etc/config/network
  uci set network.lan=interface
  uci set network.lan.proto='static'
  uci set network.lan.device='br-lan'
  uci set network.lan.ipaddr='192.168.1.1'
  uci set network.lan.netmask='255.255.255.0'
  uci set network.lan.metric='600'
  uci del network.cfg030f15.ports
  uci set network.cfg030f15.bridge_empty='1'
  uci set network.cfg030f15.mtu='1500'
  uci set network.cfg030f15.macaddr='D8:3A:DD:13:EF:AB'
  # /etc/config/wireless
  uci set wireless.wifinet0=wifi-iface
  uci set wireless.wifinet0.device='radio0'
  uci set wireless.wifinet0.mode='ap'
  uci set wireless.wifinet0.ssid='WLAN-Schnell'
  uci set wireless.wifinet0.encryption='psk2'
  uci set wireless.wifinet0.key='00000000'
  uci set wireless.wifinet0.network='lan'
  uci set wireless.radio0.channel='40'
  uci set wireless.radio0.cell_density='0'
  uci set wireless.radio0.country='DE'
  uci commit
  ```
* Then `reboot now` and you should be able to connect to the wireless network.
* Now simply follow the steps in Install and after that, the traffic of anyone connected to the wifi should be routed through your SSH tunnel/proxy!
