#!/bin/sh

DATAFILE=/home/root/rnddata
OUTFILE=/home/root/OpenSSLEncDecResults.txt
ERRFILE=/home/root/timeResults.txt

CRYPTOMOD=/lib/modules/2.6.37/kernel/crypto/ocf/cryptodev.ko
OCFMOD=/lib/modules/2.6.37/crypto/ocf/ocf_omap3_cryptok.ko

OPENSSL=/usr/bin/openssl

CRYPTOTYPE=aes-256-cbc

echo -e "\nRunning OpenSSL Encryption Decryption (${CRYPTOTYPE})"

if [ ! -r $DATAFILE ]
then
	echo "Creating 10M random data file ($DATAFILE)"
	dd if=/dev/urandom of=$DATAFILE bs=1048576 count=10
fi



## Check OpenSSL version
if [ -r $OPENSSL ]
then
	$OPENSSL version
else
	echo "Unable to find OpenSSL"
	exit 1
fi


cat /proc/cpuinfo | grep OMAP3 > /dev/null 2> /dev/null
if [ `echo $?` = "0" ]
then
	export CPU=OMAP3
else
	export CPU=other
fi



if [ $CPU = "OMAP3" ]
then
ls -l /dev/crypto > /dev/null 2> /dev/null
if [ `echo $?` = "1" ]
then
	if [ -r $CRYPTOMOD ]
	then
		echo "Installing cryptodev module"
		insmod $CRYPTOMOD
		if [ `echo $?` = "1" ]
		then
			echo "Cryptodev failed.  Test will run in SW only mode."
		else
			lsmod | grep ocf_omap3_cryptok >/dev/null
			if [ `echo $?` = "1" ]
			then
				if [ -r $OCFMOD ]
				then
					echo "Installing ocf_omap3_crypto module"
					insmod $OCFMOD ocf_omap3_crypto_dma=1
					if [ `echo $?` = "1" ]
					then
						echo "Removing cryptodev.  Running test in SW only mode."
						rm /dev/crypto
					fi
				else
					echo "Can't find OCF driver.  Running test in SW only mode."
					rm dev/crypto
				fi
			else
				echo "ocf_omap3_crypto module is already installed"
			fi
		fi
	fi
else
	echo "Cryptodev module is already installed"
	lsmod | grep ocf_omap3_cryptok >/dev/null
	if [ `echo $?` = "1" ]
	then
		if [ -r $OCFMOD ]
		then
			echo "Installing ocf_omap3_crypto module"
			insmod $OCFMOD ocf_omap3_crypto_dma=1
			if [ `echo $?` = "1" ]
			then
				echo "Removing cryptodev.  Running test in SW only mode."
				rm /dev/crypto
			fi
		else
			echo "Can't find OCF driver.  Running test in SW only mode."
			rm /dev/crypto
		fi
	else
		echo "ocf_omap3_crypto module is already installed"
	fi
fi
fi






## Encrypt
time -v $OPENSSL enc -${CRYPTOTYPE} -salt -in $DATAFILE -out $DATAFILE.enc -pass pass:crypto 2> $ERRFILE
echo "Encrypting 10M file"
egrep 'User|System|Percent|Elapsed' $ERRFILE

## Decrypt
time -v $OPENSSL enc -d -${CRYPTOTYPE} -in $DATAFILE.enc  -pass pass:crypto > $DATAFILE.dec 2> $ERRFILE
echo "Decrypting 10M file"
egrep 'User|System|Percent|Elapsed' $ERRFILE





echo -e "\n$DATAFILE=original file"
echo -e "$DATAFILE.enc=encrypted file"
echo -e "$DATAFILE.dec=decrypted file\n"
ls -l $DATAFILE $DATAFILE.enc $DATAFILE.dec

echo "Decrypted file is now being compared to the original"
echo -e "Please wait...\n"

diff $DATAFILE $DATAFILE.dec
if [ `echo $?` = "0" ]
then
	echo "### diff of $DATAFILE and $DATAFILE.dec"
	echo -e "indicates that they are the same\n"
else
	echo "### diff of $DATAFILE and $DATAFILE.dec"
	echo "indicates that they are the different!!  This should not ever happen!!"
fi


