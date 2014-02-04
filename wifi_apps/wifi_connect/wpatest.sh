#!/bin/sh
#start the supplicant in case it is not running already
killall wpa_supplicant
sleep 5

wpa_supplicant -d -Dwext,rtl8192cu -c/etc/wpa_supplicant.conf -iwlan0 -B
echo "starting wpa_supplicant"
sleep 1

$1 -p  /run/wpa_supplicant -i wlan0
