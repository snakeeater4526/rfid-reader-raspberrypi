#!/bin/bash

until [ ! -z ${ipetmasque} ]; do
echo "*****************************************************************"
echo "veuiller écrire une adresse ip et un masque en /xx valide"
echo "Exemple: 10.1.1.10/24 ou 192.168.1.10/24"
echo "*****************************************************************"
read ipetmasque
done

until [ ! -z ${passerelle} ]; do
echo "*****************************************************************"
echo "veuiller écrire une adresse ip de passerelle valide"
echo "Exemple: 10.1.1.7"
echo "*****************************************************************"
read passerelle
done

until [ ! -z ${dns} ]; do
echo "*****************************************************************"
echo "veuiller écrire une ou plusieurs adresse dns"
echo "Exemples: 8.8.8.8 ou 8.8.4.4 etc..."
echo "*****************************************************************"
read dns
done

until [ ! -z ${master} ]; do
echo "*****************************************************************"
echo "veuiller saisir l'adresse ip du serveur maitre"
echo "Exemples: 10.1.1.14 "
echo "*****************************************************************"
read master
done


sudo apt-get update
sudo apt-get upgrade 

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

clear

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
static routers=${passerelle}
static domain_name_servers=${dns}

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

sudo bash -c 'cat > /home/pi/rfid-reader-raspberrypi/clever_card_kit/01_read.py' << EOF
#!/usr/bin/env python

import os
import RPi.GPIO as GPIO
import SimpleMFRC522
import time
import socket

reader = SimpleMFRC522.SimpleMFRC522()

print("Hold a tag near the reader")

while True:
        try:
                id, text = reader.read()
                print(id)
                print(text)
                print(type(text))
                file = open("badge_id_and_name.txt","w")
                file.write('{0}'.format(id))
                file.write("\n")
                file.write('{0}'.format(text))
                file.close()

                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.connect(("8.8.8.8", 80))
                print(s.getsockname()[0])
                ip_from = s.getsockname()[0]  
                s.close()
                os.system('curl -X GET "http://${master}?device_id=3&ip_from='+ip_from+'&badge_id='+str(id)+'&badge_content='+text.replace(" ", '%20')+'"')

                if(id == 579524404115 or id == 739692225313 or id == 711892313040 or id == 841781257100 or id == 828069795733 or id == 556251098634 or id == 84282908938 or id == 427905426247):
                        GPIO.setmode(GPIO.BCM)
                        GPIO.setup(4, GPIO.OUT)
                        GPIO.output(4, GPIO.HIGH)
                        time.sleep(2)
                        GPIO.output(4, GPIO.LOW)
                else:
                        time.sleep(2)

        except:
                os.system('curl -X GET "http://${master}?device_id=3&ip_from='+ip_from+'&badge_id='+str(id)+'&badge_content=null"')
                #GPIO.setmode(GPIO.BCM)
                #GPIO.setup(4, GPIO.OUT)
                #GPIO.output(4, GPIO.HIGH)
                time.sleep(2)
                #GPIO.output(4, GPIO.LOW)

        finally:
                print("cleaning up")
EOF

sudo bash -c 'cat > /etc/rc.local' << EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "My IP address is %s\n" "$_IP"
fi

(cd /home/pi/rfid-reader-raspberrypi/clever_card_kit/ && sudo python 01_read.py) &


exit 0
EOF

sudo shutdown -r +1

echo "*****************************************************************"
echo "Installation Fini"
echo "Le Raspberry Pi va redemarrer dans 1 minutes"
echo "Vous pouvez forcer ce redémarrage avec la commande: sudo reboot"
echo "*****************************************************************"
