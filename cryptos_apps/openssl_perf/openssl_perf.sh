#!/bin/sh


CRYPTOMOD=/lib/modules/2.6.37/kernel/crypto/ocf/cryptodev.ko
OCFMOD=/lib/modules/2.6.37/crypto/ocf/ocf_omap3_cryptok.ko


OPENSSL=/usr/bin/openssl


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
						rmmod cryptodev
					fi
				else
					echo "Can't find OCF driver.  Running test in SW only mode."
					rmmod cryptodev
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
				rmmod cryptodev
			fi
		else
			echo "Can't find OCF driver.  Running test in SW only mode."
			rmmod cryptodev
		fi
	else
		echo "ocf_omap3_crypto module is already installed"
	fi
fi
fi



if [ -r $OPENSSL ]
then
	$OPENSSL version
else
	echo "Unable to find OpenSSL"
	exit 1
fi

echo "################################"
echo "Running OpenSSL Speed tests.  "
echo "There are 7 tests and each takes 15 seconds..."
echo

TEMP=/home/root/temp

echo "Running aes-128-cbc test.  Please Wait..."
time -v $OPENSSL speed -evp aes-128-cbc -engine cryptodev > $TEMP 2>&1
egrep 'Doing|User|System|Percent|Elapsed' $TEMP

echo "Running aes-192-cbc test.  Please Wait..."
time -v $OPENSSL speed -evp aes-192-cbc -engine cryptodev > $TEMP 2>&1
egrep 'Doing|User|System|Percent|Elapsed' $TEMP

echo "Running aes-256-cbc test.  Please Wait..."
time -v $OPENSSL speed -evp aes-256-cbc -engine cryptodev > $TEMP 2>&1
egrep 'Doing|User|System|Percent|Elapsed' $TEMP

echo "Running des-cbc test.  Please Wait..."
time -v $OPENSSL speed -evp des-cbc -engine cryptodev > $TEMP 2>&1
egrep 'Doing|User|System|Percent|Elapsed' $TEMP

echo "Running des3 test.  Please Wait..."
time -v $OPENSSL speed -evp des3 -engine cryptodev > $TEMP 2>&1
egrep 'Doing|User|System|Percent|Elapsed' $TEMP

echo "Running sha1 test.  Please Wait..."
time -v $OPENSSL speed -evp sha1 -engine cryptodev > $TEMP 2>&1
egrep 'Doing|User|System|Percent|Elapsed' $TEMP

echo "Running md5 test.  Please Wait..."
time -v $OPENSSL speed -evp md5 -engine cryptodev > $TEMP 2>&1
egrep 'Doing|User|System|Percent|Elapsed' $TEMP

rm $TEMP


