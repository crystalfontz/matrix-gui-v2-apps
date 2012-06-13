#!/bin/sh

KEYFILE=/home/root/privatekey.pem
PUBKEY=/home/root/pubkey.pem


OPENSSL=/usr/bin/openssl

echo -e "\nGenerating Public Key from ${KEYFILE}"


if [ ! -r $CERTFILE ]
then
	echo "Private Key does not exist.  Generate certificate first before generating a public key"
	exit 1
else
	$OPENSSL rsa -in $KEYFILE -pubout > $PUBKEY
	echo -e "\nPublic Key written to ${PUBKEY}\n"
fi

cat $PUBKEY

