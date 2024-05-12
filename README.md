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

* Install the dependencies (skip this step if you followed the [Exmaple](#example-use-a-raspberry-pi-4-as-an-access-point-that-automatically-routes-all-traffic-through-an-http-proxy-or-an-ssh-tunnel) below)
  * OpenWRT/ImmortalWRT:
    ```bash
    opkg update
    opkg install coreutils-base64 procps-ng-pkill coreutils-dirname openvpn ncat openssh-client sshpass bash git-http
    ```
    You also need to install [GOST](https://gost.run/en/) for the proxy_connect.sh script.<br>
    If you are using ImmortalWRT, then you can also install it by using the following command:
    ```bash
    opkg install gost
    ```
  * Ubuntu:
    ```bash
    apt install coreutils procps openvpn ncat openssh-client sshpass bash git
    ```

* If you are using OpenWRT/ImmortalWRT, make sure that the gateway metric of your WAN/LAN interface is set to 600. You can find this setting under
  ```
  Network->Interfaces->Edit button on your WAN interface->Advanced Settings->Use gateway metric
  ```
  This is already configured correctly if you followed the install steps in the [Example](#example-use-a-raspberry-pi-4-as-an-access-point-that-automatically-routes-all-traffic-through-an-http-proxy-or-an-ssh-tunnel) down below.

* Clone this repository
  ```bash
  git clone https://github.com/PocketMiner82/ConnectSSHTunnel.git
  cd ConnectSSHTunnel
  ```

* Copy the correct badvpn binary or build your own. The target name MUST be `badvpn-tun2socks`. The prebuilt binaries are built from [here](https://github.com/ambrop72/badvpn). Also see the LICENSE_badvpn file in the directory. For OpenWRT/ImmortalWRT (aarch64) on a Raspberry Pi 4:
  ```bash
  cp badvpn_compiled/badvpn-tun2socks_openwrt_rpi4_aarch64 badvpn-tun2socks
  ```

* Run the script once to copy the config file.
  ```bash
  ./connect_ssh_tunnel.sh
  ```

* Edit `config.sh` (`nano config.sh` if you have nano installed) DO NOT edit `default_config.sh`!

* Now connect the Device to the Network where you want/have to use the ssh tunnel or proxy connect script.

* For SSH Tunnel: Make sure, the certificate of the server you specified in config to connect is trusted. If you are not sure run this script (replace the placeholders before!), which will open a normal ssh connection to the server:
  ```bash
  ./ssh_open.sh <server_port> <server_user>
  ```
  Accept the certificate.

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
  (/bin/bash /path/to/connect_ssh_server.sh &) > /dev/null 2>&1
  ```
  Or for proxy_connect.sh:
  ```bash
  (/bin/bash /path/to/proxy_connect.sh &) > /dev/null 2>&1
  ```

## Example: Use a Raspberry Pi 4 as an access point that automatically routes all traffic through an HTTP proxy or an SSH tunnel
* **Warning! This is meant to be used only in the local area network and not as a "real" router/gateway that is directly connected to the internet. Use with care!**
* Open [this Website](https://firmware-selector.immortalwrt.org/?target=bcm27xx%2Fbcm2711&id=rpi-4) to configure ImmortalWRT. This instruction was tested on version 23.05.1.
* You need to put these packages in `Installed Packages` (replace the default ones with these):
  ```
  automount base-files bcm27xx-gpu-fw bcm27xx-utils brcmfmac-nvram-43455-sdio busybox ca-bundle cpufreq cypress-firmware-43455-sdio dnsmasq-full dropbear firewall4 fstools ipv6helper iwinfo kmod-brcmfmac kmod-fs-vfat kmod-hwmon-pwmfan kmod-nft-offload kmod-nls-cp437 kmod-nls-iso8859-1 kmod-sound-arm-bcm2835 kmod-sound-core kmod-thermal kmod-usb-hid libc libgcc libustream-openssl logd mkf2fs mtd netifd nftables opkg partx-utils ppp ppp-mod-pppoe procd procd-seccomp procd-ujail uci uclient-fetch urandom-seed wpad-basic-mbedtls coreutils-base64 procps-ng-pkill coreutils-dirname openvpn ncat openssh-client sshpass bash git-http gost nano-full htop libsensors kmod-rtl8812au-ac kmod-usb-net-rtl8152 liblucihttp-lua liblucihttp0 luci luci-app-firewall luci-app-opkg luci-app-sqm luci-base luci-compat luci-lib-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-theme-bootstrap rpcd-mod-luci 
  ```
  You need to put this script in the `Script to run on first boot (uci-defaults)` section:
  ```bash
  # /etc/config/dhcp
  uci del dhcp.lan
  # /etc/config/dropbear
  uci set dropbear.@dropbear[0].GatewayPorts='on'
  uci del dropbear.@dropbear[0].Interface
  # /etc/config/firewall
  uci del firewall.cfg02dc81.network
  uci del firewall.cfg03dc81.network
  uci add_list firewall.cfg03dc81.network='wan'
  uci add_list firewall.cfg03dc81.network='wan6'
  uci add_list firewall.cfg02dc81.device='tun0'
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
  uci del wireless.default_radio0
  uci commit
  
  cat << "EOF" > /etc/uci-defaults/99-connectsshtunnel
  # /etc/config/dhcp
  uci set dhcp.lan=dhcp
  uci set dhcp.lan.interface='lan'
  uci set dhcp.lan.start='100'
  uci set dhcp.lan.limit='150'
  uci set dhcp.lan.leasetime='12h'
  uci set dhcp.lan.start='10'
  uci set dhcp.lan.limit='240'
  uci set dhcp.@dnsmasq[0].rebind_protection='0'
  uci del dhcp.@dnsmasq[0].local
  uci del dhcp.@dnsmasq[0].domainneeded
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
  uci set wireless.wifinet0.ssid='MyAP'
  uci set wireless.wifinet0.encryption='psk2'
  uci set wireless.wifinet0.key='00000000'
  uci set wireless.wifinet0.network='lan'
  uci set wireless.radio0.channel='40'
  uci set wireless.radio0.cell_density='0'
  uci set wireless.radio0.country='DE'
  uci commit
  
  sed -i -E 's@https://mirrors.vsean.net/openwrt/(.*)/@https://downloads.immortalwrt.org/\1/@g' /etc/opkg/distfeeds.conf
  reboot now
  EOF
  
  reboot now
  ```
* Click on the `REQUEST BUILD` button and wait until the firmware is built. Then download the FACTORY image.
* Use a tool like the [Raspberry Pi Imager](https://github.com/raspberrypi/rpi-imager) to flash the image to a USB Stick
* Open the `cmdline.txt` file in the boot partition of the stick and change the `root=...` to `root=/dev/sda2`
* (If you run out of space later on, you may want to increase the ext4 partition (the second partition) that was created by the installer on the stick to fill the whole stick using a tool like [GParted](https://gparted.org/))
* Plug in the stick and connect an ethernet cable to a router that provides internet without proxy or ssh tunnel (e.g. your home router).
* Then connect power to the Pi. It will reboot twice. The default configuration is an example for enabeling the 5 GHz Band in Germany, with the SSID "MyAP" and the password "00000000". You should change those values! You also want to open the [web interface](http://immortalwrt) and set a password for the root user!
* PS: you should also be able now to SSH into the Pi by using `ssh root@immortalwrt`
* Now simply follow the steps in [Install](#install-on-raspberry-pi-4-with-openwrtimmortalwrt) and after that, the traffic of anyone connected to the wifi should be routed through your SSH tunnel and/or HTTP proxy!
<details>
 <summary>Old, manual method</summary>

 * Download the default FACTORY image.
 * Use a tool like the [Raspberry Pi Imager](https://github.com/raspberrypi/rpi-imager) to flash the image to a USB Stick
 * Open the `cmdline.txt` file in the boot partition of the stick and change the `root=...` to `root=/dev/sda2`
 * (If you run out of space later on, you may want to increase the ext4 partition (the second partition) that was created by the installer on the stick to fill the whole stick using a tool like [GParted](https://gparted.org/))
 * Plug the stick in the Raspberry Pi, connect an ethernet cable to your computer and the Pi's LAN port and connect power to the Raspberry Pi
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
   # /etc/config/dropbear
   uci set dropbear.@dropbear[0].GatewayPorts='on'
   uci del dropbear.@dropbear[0].Interface
   # /etc/config/firewall
   uci del firewall.cfg02dc81.network
   uci del firewall.cfg03dc81.network
   uci add_list firewall.cfg03dc81.network='wan'
   uci add_list firewall.cfg03dc81.network='wan6'
   uci add_list firewall.cfg02dc81.device='tun0'
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
   uci del wireless.default_radio0
   uci commit
   ```
 * Then `poweroff now`, disconnect the power, connect the ethernet cable to a router that provides internet, reconnect the power
 * Connect to the Pi again:
   ```bash
   ssh root@immortalwrt
   ```
 * Run the following commands to get the internal wifi working in AP mode<br>
   This is an example config for enabeling the 5 GHz Band in Germany, with the SSID "MyAP" and the password "00000000". You should change those values!
   ```bash
   # /etc/config/dhcp
   uci set dhcp.lan=dhcp
   uci set dhcp.lan.interface='lan'
   uci set dhcp.lan.start='100'
   uci set dhcp.lan.limit='150'
   uci set dhcp.lan.leasetime='12h'
   uci set dhcp.lan.start='10'
   uci set dhcp.lan.limit='240'
   uci set dhcp.@dnsmasq[0].rebind_protection='0'
   uci del dhcp.@dnsmasq[0].local
   uci del dhcp.@dnsmasq[0].domainneeded
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
   uci set wireless.wifinet0.ssid='MyAP'
   uci set wireless.wifinet0.encryption='psk2'
   uci set wireless.wifinet0.key='00000000'
   uci set wireless.wifinet0.network='lan'
   uci set wireless.radio0.channel='40'
   uci set wireless.radio0.cell_density='0'
   uci set wireless.radio0.country='DE'
   uci commit
   ```
 * Use the follwing command to use the official immortal wrt repositories for installing packages later:
   ```bash
   sed -i -E 's@https://mirrors.vsean.net/openwrt/(.*)/@https://downloads.immortalwrt.org/\1/@g' /etc/opkg/distfeeds.conf
   ```
 * You also might want to install nano-full to simplify editing config files later and htop to monitor cpu usage
   ```bash
   opkg update
   opkg install nano-full htop libsensors
   ```
 * Then `reboot now` and you should be able to connect to the wireless network.
</details>
