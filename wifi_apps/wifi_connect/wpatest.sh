#!/bin/sh
#check if udhcpc is already started for wlan0 if it doesnt, start it
udhcpAlreadyInstalled=`ps | grep -c -E "udhcpc -R -b -p /var/run/udhcpc.wlan0.pid"`
if [ $udhcpAlreadyInstalled -eq 1 ]; then
       udhcpc -R -b -p /var/run/udhcpc.wlan0.pid -i wlan0
       sleep 1
fi

#start the supplicant in case it is not running already
killall wpa_supplicant
sleep 5

wpa_supplicant -d -Dwext,rtl8192cu -c/etc/wpa_supplicant.conf -iwlan0 -B
echo "starting wpa_supplicant"
sleep 1

wpa_gui-e -i wlan0 -geometry 480x240+0+0
