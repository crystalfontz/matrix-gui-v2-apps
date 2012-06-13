#!/bin/sh

CERTFILE=/home/root/certificate.pem
KEYFILE=/home/root/privatekey.pem

OPENSSL=/usr/bin/openssl


if [ `pidof openssl` ]
then
	echo "Server is already running.  Exiting..."
	exit
fi

echo -e "\nStarting SSL-enabled web server"


if [ ! -r $CERTFILE ]
then
	echo "Certificate does not exist.  Generating new certificate before starting server..."
	/usr/bin/openssl_gen_cert.sh >> /dev/NULL
fi

echo "Starting server..."
echo 

ifconfig | egrep 'eth|inet'
echo 

echo "Point a browser from some connected client machine to one"
echo "of the IP addresses above (inet addr:)."
echo "Using the format https://[IP address]:4433"
echo
echo



$OPENSSL s_server -cert $CERTFILE -key $KEYFILE -www >> /dev/NULL &
