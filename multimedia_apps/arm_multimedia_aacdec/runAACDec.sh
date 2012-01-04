#!/bin/sh

machine_type="`cat /etc/hostname`"
filename="/usr/share/ti/audio/HistoryOfTI.aac"
if [ ! -f $filename ]; then
        echo "Audio clip not found"
        exit 1
fi
echo ""
echo ""
if [ "$machine_type" = "am37x-evm" ]; then
        amixer cset name='HeadsetL Mixer AudioL1' on
        amixer cset name='HeadsetR Mixer AudioR1' on
        amixer -c 0 set Headset 1+ unmute
elif [ "$machine_type" = "am335x-evm" ]; then
	amixer cset name='PCM Playback Volume' 127
fi
echo ""
echo "Length of audio clip: 18 seconds"
echo ""
echo "Launch GStreamer pipeline"
echo ""
gst-launch-0.10 filesrc location=$filename ! faad ! alsasink