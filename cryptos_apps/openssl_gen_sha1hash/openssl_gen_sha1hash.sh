#!/bin/sh

DATAFILE=/home/root/rnddata


OPENSSL=/usr/bin/openssl

echo -e "\nGenerate SHA1 Hash"

if [ ! -r $DATAFILE ]
then
	echo "Creating 10M random data file ($DATAFILE)"
	echo "Please Wait..."
	dd if=/dev/urandom of=$DATAFILE bs=1048576 count=10
fi


$OPENSSL dgst -sha1 $DATAFILE 


