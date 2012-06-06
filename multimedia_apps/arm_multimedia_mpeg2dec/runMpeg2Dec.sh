#!/bin/sh

machine_type="`cat /etc/hostname`"
if [ "$machine_type" = "am335x-evm" ]; then
        resolution="`fbset | awk '/geometry/ {print $2"x"$3}'`"
        if [ "$resolution" = "800x480" ]; then
                filename="/usr/share/ti/video/HistoryOfTI-WVGA.m2v"
        elif [ "$resolution" = "480x272" ]; then
                filename="/usr/share/ti/video/HistoryOfTI-WQVGA.m2v"
        fi
else
	default_display="`cat /sys/devices/platform/omapdss/manager0/display`"
	if [ "$default_display" = "dvi" ]; then
        	if [ "$machine_type" = "beagleboard" ]; then
                	filename="/usr/share/ti/video/HistoryOfTI-VGA.m2v"
        	else
                	filename="/usr/share/ti/video/HistoryOfTI-480p.m2v"
        	fi
	else
        	if [ "$machine_type" = "am37x-evm" ]; then
                	filename="/usr/share/ti/video/HistoryOfTI-VGA-r.m2v"
        	elif [ "$machine_type" = "am3517-evm" ]; then
                	filename="/usr/share/ti/video/HistoryOfTI-WQVGA.m2v"
        	fi
	fi
fi
if [ ! -f $filename ]; then
        echo "Video clip not found"
        exit 1
fi
gst-launch-0.10 filesrc location=$filename ! mpegvideoparse ! ffdec_mpeg2video ! ffmpegcolorspace ! fbdevsink
