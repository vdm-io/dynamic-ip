#!/bin/bash

# simple basic random
function getKey () {
    echo $(tr -dc 'A-HJ-NP-Za-km-z2-9' < /dev/urandom | dd bs=128 count=1 status=none)
}

# Variables
TRUE=1
VDMUSER="vdm"
VDMHOME="/home/vdm"
VDMSCRIPT="https://raw.githubusercontent.com/vdm-io/dynamic-ip/master/getip.sh"
VDMIPSERVER="https://www.vdm.io/getip"

# Require script to be run via sudo, but not as root
#if [[ $EUID -ne 0 ]]; then
#
#    echo "Script must be run with root privilages!"
#    exit 1
#fi

# Set cronjob without removing existing
if [ -f $VDMHOME/getip.cron ]; then
	echo "Crontab already configured for updates...Skipping"
else
	echo -n "Adding crontab entry for continued updates..."
	# check if user crontab is set
	currentCron=$(crontab -u $VDMUSER -l 2>/dev/null)
	if [[ -z "${currentCron// }" ]]; then
		currentCron="# VDM crontab settings"
		echo "$currentCron" > $VDMHOME/getip.cron
	else	
		echo "$currentCron" > $VDMHOME/getip.cron
	fi
	# check if the MAILTO is already set
	if [[ $currentCron != *"MAILTO"* ]]; then
		echo "MAILTO=\"\"" >> $VDMHOME/getip.cron
		echo "" >> $VDMHOME/getip.cron
	fi
	# check if the @reboot curl -s $VDMSCRIPT | sudo bash is already set
	if [[ $currentCron != *"@reboot curl -s $VDMSCRIPT | sudo bash"* ]]; then
		echo "@reboot curl -s $VDMSCRIPT | sudo bash" >> $VDMHOME/getip.cron
	fi
	# check if the @reboot curl -s $VDMSCRIPT | sudo bash is already set
	if [[ $currentCron != *"*/7 * * * * curl -s $VDMSCRIPT | sudo bash"* ]]; then
		echo "*/7 * * * * curl -s $VDMSCRIPT | sudo bash" >> $VDMHOME/getip.cron
	fi
	# set the user cron
	crontab -u $VDMUSER $VDMHOME/getip.cron
	echo "Done"
fi

# Set update key
if [ -f $VDMHOME/getip.key ]; then
	echo "Update key already set!"
else
	echo -n "Setting the update key..."
	echo $(getKey) > $VDMHOME/getip.key
	echo "Done"
fi

# Get update key
serverKey=$(<"$VDMHOME/getip.key")

# check if vdm access was set
accessToke=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-KEY: $serverKey" --silent $VDMIPSERVER)

if [[ "$accessToke" != "$TRUE" ]]; then
	read -s -p "Please enter your VDM access key: " vdmAccessKey
	echo ""
	echo -n "One moment while we set your access to the VDM system..."
	resultAccess=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-TRUST: $vdmAccessKey" -H "VDM-KEY: $serverKey" --silent $VDMIPSERVER)
	if [[ "$resultAccess" != "$TRUE" ]]; then
		echo " >> YOUR VDM ACCESS KEY IS INCORRECT! <<"
		exit 1
	fi
	echo "Done"
else
	echo "Access granted to the VDM system."
fi

# getting the dynamic ip from vdm system
echo -n "getting the Dynamic IP..."
resultUpdate=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-KEY: $serverKey" --silent $VDMIPSERVER)
if [[ "$resultUpdate" != "$TRUE" ]]; then
	echo " >> YOUR SERVER KEY IS INCORRECT! <<"
	exit 1
fi
echo "Done"
