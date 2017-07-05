#!/bin/bash

# simple basic random
function getKey () {
    echo $(tr -dc 'A-HJ-NP-Za-km-z2-9' < /dev/urandom | dd bs=128 count=1 status=none)
}

# Variables
TRUE=1
VDMUSER="vdm"
VDMHOME="/home/vdm"
VDMSCRIPT="https://raw.githubusercontent.com/vdm-io/dynamic-ip/$BRANCH/setip.sh"
VDMIPSERVER="https://www.vdm.io/setip"

# Require script to be run via sudo, but not as root
#if [[ $EUID -ne 0 ]]; then
#
#    echo "Script must be run with root privilages!"
#    exit 1
#fi

# Set cronjob without removing existing
if [ -f $VDMHOME/vdmip.cron ]; then
	echo "Crontab already configured for updates...Skipping"
else
	echo -n "Adding crontab entry for continued updates..."
	currentCron=$(crontab -u $VDMUSER -l)
	echo "$currentCron" > $VDMHOME/vdmip.cron
	# check if the MAILTO is already set
	if [[ $currentCron != *"MAILTO"* ]]; then
		echo "MAILTO=\"\"" >> $VDMHOME/vdmip.cron
		echo "" >> $VDMHOME/vdmip.cron
	fi
	# check if the @reboot curl -s $VDMSCRIPT | sudo bash is already set
	if [[ $currentCron != *"@reboot curl -s $VDMSCRIPT | sudo bash"* ]]; then
		echo "@reboot curl -s $VDMSCRIPT | sudo bash" >> $VDMHOME/vdmip.cron
	fi
	# check if the @reboot curl -s $VDMSCRIPT | sudo bash is already set
	if [[ $currentCron != *"*/30 * * * * curl -s $VDMSCRIPT | sudo bash"* ]]; then
		echo "*/30 * * * * curl -s $VDMSCRIPT | sudo bash" >> $VDMHOME/vdmip.cron
	fi
	# set the user cron
	crontab -u $VDMUSER $VDMHOME/vdmip.cron
	echo "Done"
fi

# Set update key
if [ -f $VDMHOME/ip.key ]; then
	echo "Update key already set!"
else
	echo -n "Setting the update key..."
	echo $(getKey) > $VDMHOME/ip.key
	echo "Done"
fi

# Get update key
serverKey=$(<"$VDMHOME/ip.key")

# check if vdm access was set
accessToke=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36"  --silent --data-urlencode "key=$serverKey" $VDMIPSERVER)

if [[ "$accessToke" != "$TRUE" ]]; then
	read -s -p "Please enter your VDM access key: " vdmAccessKey
	echo ""
	echo -n "One moment while we set your access to the VDM system..."
	resultAccess=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36"  --silent --data-urlencode "trust=$vdmAccessKey" --data-urlencode  "key=$serverKey" $VDMIPSERVER)
	if [[ "$resultAccess" != "$TRUE" ]]; then
		echo " >> YOUR VDM ACCESS KEY IS INCORRECT! <<"
		exit 1
	fi
	echo "Done"
else
	echo "Access granted to the VDM system."
fi

# get this server IP
IPNOW="$(dig +short myip.opendns.com @resolver1.opendns.com)"
# store the IP in the HOSTNAME file
echo -n "Setting/Update the Dynamic IP..."
resultUpdate=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36"  --silent --data-urlencode "ip=$IPNOW" --data-urlencode "key=$serverKey" $VDMIPSERVER)
if [[ "$resultUpdate" != "$TRUE" ]]; then
	echo " >> YOUR SERVER KEY IS INCORRECT! << $resultUpdate"
	exit 1
fi
echo "Done"
