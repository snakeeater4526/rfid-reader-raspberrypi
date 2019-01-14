#!/bin/bash
sudo apt-get update
sudo apt-get upgrade -y

echo "dtparam=spi=on">>/boot/config.txt
cd /boot
touch ssh

cd /home/pi
sudo apt-get install python-dev -y
git clone https://github.com/simonmonk/SPI-Py.git
cd SPI-Py
sudo python setup.py install 
sudo python3 setup.py install 
cd /home/pi
git clone https://github.com/simonmonk/squid.git
cd squid
sudo python setup.py install 
sudo python3 setup.py install 
sudo apt-get install alsa-utils -y
sudo apt-get install festival -y
sudo pip3 install guizero
cd /home/pi

until [ ! -z ${ipetmasque} ]; do
echo " "
echo "veuiller écrire une adresse ip et un masque en /xx valide"
echo "Exemple: 10.1.1.10/24 ou 192.168.1.10/24"
read ipetmasque
done

sudo bash -c 'cat > /etc/dhcpcd.conf' << EOF
# A sample configuration for dhcp# A sample configuration for dhcpcd.
# See dhcpcd.conf(5) for details.

# Allow users of this group to interact with dhcpcd via the control socket.
#controlgroup wheel

# Inform the DHCP server of our hostname for DDNS.
hostname

# Use the hardware address of the interface for the Client ID.
clientid
# or
# Use the same DUID + IAID as set in DHCPv6 for DHCPv4 ClientID as per RFC4361.
# Some non-RFC compliant DHCP servers do not reply with this set.
# In this case, comment out duid and enable clientid above.
#duid

# Persist interface configuration when dhcpcd exits.
persistent

# Rapid commit support.
# Safe to enable by default because it requires the equivalent option set
# on the server to actually work.
option rapid_commit

# A list of options to request from the DHCP server.
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
# Most distributions have NTP support.
option ntp_servers
# Respect the network MTU. This is applied to DHCP routes.
option interface_mtu

# A ServerID is required by RFC2131.
require dhcp_server_identifier

# Generate Stable Private IPv6 Addresses instead of hardware based ones
slaac private

# Example static IP configuration:
interface eth0
static ip_address=${ipetmasque}
#static ip6_address=fd51:42f8:caae:d92e::ff/64
#static routers=192.168.0.1
#static domain_name_servers=192.168.0.1 8.8.8.8 fd51:42f8:caae:d92e::1

# It is possible to fall back to a static IP if DHCP fails:
# define static profile
#profile static_eth0
#static ip_address=192.168.1.23/24
#static routers=192.168.1.1
#static domain_name_servers=192.168.1.1

# fallback to static profile on eth0
#interface eth0
#fallback static_eth0cd.
# See dhcpcd.conf(5) for details.
EOF

echo "Finished Installation"
echo "Please REBOOT using: $ sudo reboot"
