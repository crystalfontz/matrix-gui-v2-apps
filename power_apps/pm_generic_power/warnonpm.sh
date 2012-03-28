# Module: warnonpm
#
# Description: This script can be used as a wrapper to check for boards and
#              software versions that have PM issues and print warnings to
#              the screen.
# 
# Copyright (C) 2012 Texas Instruments Incorporated
# http://www.ti.com/
#
#  Redistribution and use in source and binary forms, with or withou
#  modification, are permitted provided that the following conditions
#  are met:
#
#  Redistributions of source code must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#  
#  Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the
#  distribution.
#
#  Neither the name of Texas Instruments Incorporated nor the names of
#  its contributors may be used to endorse or promote products derived
#  from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# This script will do some PM checks and then use the parameters it was
# given to invoke the next script.  For example to call setclockspeed.sh
# with a value of 600000 do:
# ./warnonpm.sh setclockspeed.sh 600000

print_pm_warning() {
cat << EOM

 The version of the CPLD code used on your EVM does not support power
 management operations.  Although these operations are not available through the
 matrix application launcher, they are supported in the kernel.  If you
 wish to evaluate power management on this EVM you may do so using
 either of the following options:
    - Use the sysfs attributes from the serial console to access the
      power management features.  You can find more information on this
      in the Power Management user's Guide at:
        http://processors.wiki.ti.com/index.php/Power_Management_Users_Guide
      NOTE: There is a known issue in older versions of the CPLD code
            than can cause an i2c bus lockup when doing power management
            operations.  If you encounter a lockup you will need to
            power cycle your EVM.  To avoid this lockup, an update of the CPLD
            version is required.
    - Update your CPLD software version and the board EEPROM to reflect this
      update.  You can find instructions on how to do this at:
        <URL HERE>

EOM
}

# Get the eeprom values if they exist and save them to file in
# the /var/volatile directory so that they will have to be
# regenerated on each reboot.  If /var/volatile does not exist then
# we will have to read the EEPROMs each time.
eeprom_board="x"
eeprom_daughtercard="x"
eeprom_cpld="x"
get_eeprom_values(){
    # Base EEPROM locations
    base_eeprom="/sys/devices/platform/omap/omap_i2c.1/i2c-1/"

    if [ ! -d $base_eeprom ]
    then
        # There was no EEPROM found so we assume this is a board
        # without a CPLD
        return 0
    fi

    # The EEPROM at 1-0050 has the board name in it in bytes 5-12
    # So first let's check that the board is an EVM and not some other
    # board that has no CPLD.
    cd $base_eeprom/1-0050

    if [ -e /var/volatile/eeprom_board ]
    then
        eeprom_board=`cat /var/volatile/eeprom_board`
    else
        eeprom_board=`head eeprom -c 12 | cut -b 5-12`
        echo "$eeprom_board" > /var/volatile/eeprom_board
    fi

    # The EEPROM on the daughtercard at 1-0051 has the CPLD version in bytes
    # 61-68 and the daughtercard type in bytes 5-12
    # The EEPROM at 1-0051 has the daughtercard name in it in bytes 5-12
    # So first let's check that the daughtercard is the GP and not some other
    # daughtercard
    cd $base_eeprom/1-0051

    if [ -e /var/volatile/eeprom_daughtercard ]
    then
        eeprom_daughtercard=`cat /var/volatile/eeprom_daughtercard`
    else
        eeprom_daughtercard=`head eeprom -c 12 | cut -b 5-12`
        echo "$eeprom_daughtercard" > /var/volatile/eeprom_daughtercard
    fi

    # The EEPROM at 1-0051 has the CPLD version in it in bytes 61-68
    if [ -e /var/volatile/eeprom_cpld ]
    then
        eeprom_cpld=`cat /var/volatile/eeprom_cpld`
    else
        eeprom_cpld=`head eeprom -c 68 | cut -b 61-68`
        echo "$eeprom_cpld" > /var/volatile/eeprom_cpld
    fi
}

# Check if the CPLD version is sufficient to allow for PM operations
# This is only needed for the EVM so also check if this is a beaglebone
# or not.  The CPLD with the potential to lockup the i2c bus and hang
# the board during PM operations is only on the general purpose
# daughter card.
check_cpld_version() {
    # Check if we have already marked PM as enabled
    if [ -e /var/volatile/enable_pm ]
    then
        # PM is supported so go on
        return 0
    fi

    # Get the eeprom values
    get_eeprom_values

    if [ "$eeprom_board" != "A33515BB" ]
    then
        # This is NOT an EVM
        touch /var/volatile/enable_pm
        return 0
    fi

    if [ "$eeprom_daughtercard" != "A335GPBD" ]
    then
        # This is NOT a general purpose daughtercard
        touch /var/volatile/enable_pm
        return 0
    fi

    # check that the eeprom CPLD version looks valid.  The CPLD version
    # should look like CPLD<number>.<number><alpha>
    echo "$eeprom_cpld" | grep -e "CPLD[0-9]\.[0-9].*" > /dev/null
    if [ "$?" = "1" ]
    then
        echo "INVALID CPLD VERSION FOUND"
        print_pm_warning
        exit 1
    fi

    # Now that we know the CPLD has a valid version, check to make sure it
    # is greater than 1.0D.  To do this we will combine the version with
    # the 1.0D version, sort the two versions in reverse order, and then
    # grab the first entry.  If that entry is CPLD1.0D then that means the
    # CPLD version we read was:
    #   - Garbage (i.e. not programmed)
    #   - Less than 1.0D
    #   - 1.0D as well
    # Therefore we want to not do PM operations
    broken_ver="CPLD1.0D"
    sorted=`echo -e "$eeprom_cpld""\n""$broken_ver" | sort -r`
    first=`echo $sorted | cut -d ' ' -f1`

    if [ "$first" = "$broken_ver" ]
    then
        # This is a version that is not supported
        echo "FOUND UNSUPPORTED CPLD VERSION ($eeprom_cpld)"
        print_pm_warning
        exit 1
    else
        # This is a supported version
        touch /var/volatile/enable_pm
    fi
}

# Get the machine type
. /etc/init.d/functions

case $(machine_id) in
    am335xevm )
        check_cpld_version
        ;;
    * )
        ;;
esac

# Invoke the real command
$*
