#!/bin/sh

default_display="`cat /sys/devices/platform/omapdss/manager0/display`"
if [ "$default_display" = "dvi" ]; then
	echo 0 > /sys/devices/platform/omapdss/display2/enabled
	echo 0 > /sys/devices/platform/omapdss/overlay0/enabled
	echo "" > /sys/devices/platform/omapdss/overlay0/manager
	echo "480,640" > /sys/class/graphics/fb0/virtual_size
	fbset -fb /dev/fb0 -xres 480 -yres 640
	echo "lcd" > /sys/devices/platform/omapdss/overlay0/manager
	echo "lcd" > /sys/devices/platform/omapdss/manager0/display
	echo 1 > /sys/devices/platform/omapdss/display0/enabled
	echo 1 > /sys/devices/platform/omapdss/overlay0/enabled
	matrix-gui-dvi-2.0.sh stop
	/etc/init.d/matrix-gui-2.0 start
else
	echo "LCD display already enabled"
fi
