#!/bin/bash
#/--------------------------------------------------------------------------------------------------------|  www.vdm.io  |------/
#    __      __       _     _____                 _                                  _     __  __      _   _               _
#    \ \    / /      | |   |  __ \               | |                                | |   |  \/  |    | | | |             | |
#     \ \  / /_ _ ___| |_  | |  | | _____   _____| | ___  _ __  _ __ ___   ___ _ __ | |_  | \  / | ___| |_| |__   ___   __| |
#      \ \/ / _` / __| __| | |  | |/ _ \ \ / / _ \ |/ _ \| '_ \| '_ ` _ \ / _ \ '_ \| __| | |\/| |/ _ \ __| '_ \ / _ \ / _` |
#       \  / (_| \__ \ |_  | |__| |  __/\ V /  __/ | (_) | |_) | | | | | |  __/ | | | |_  | |  | |  __/ |_| | | | (_) | (_| |
#        \/ \__,_|___/\__| |_____/ \___| \_/ \___|_|\___/| .__/|_| |_| |_|\___|_| |_|\__| |_|  |_|\___|\__|_| |_|\___/ \__,_|
#                                                        | |
#                                                        |_|
#/-------------------------------------------------------------------------------------------------------------------------------/
#
#	@version		1.0.0
#	@build			21st July, 2017
#	@package		Dynamic IP
#	@author			Llewellyn van der Merwe <https://github.com/Llewellynvdm>
#	@copyright		Copyright (C) 2015. All Rights Reserved
#	@license		GNU/GPL Version 2 or later - http://www.gnu.org/licenses/gpl-2.0.html
#
#/-----------------------------------------------------------------------------------------------------------------------------/

############################ GLOBAL ##########################
ACTION="setip"
######### DUE TO NOT BEING ABLE TO INCLUDE DYNAMIC ###########

#################### UPDATE TO YOUR NEEDS ####################
##############################################################
##############                                      ##########
##############               CONFIG                 ##########
##############                                      ##########
##############################################################
REPOURL="https://raw.githubusercontent.com/vdm-io/dynamic-ip/master/"
VDMIPSERVER="https://www.vdm.io/$ACTION"

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
function main () {
	## make sure cron is set
	setCron
	## get the local server key
	getLocalKey
	## check access (set if not ready)
	setAccessToken
	## update IP
	setIP
}

##############################################################
##############                                      ##########
##############              DEFAULTS                ##########
##############                                      ##########
##############################################################
VDMUSER=$(whoami)
VDMHOME=~/
VDMSCRIPT="${REPOURL}$ACTION.sh"
VDMSERVERKEY=''
TRUE=1

##############################################################
##############                                      ##########
##############             FUNCTIONS                ##########
##############                                      ##########
##############################################################

# Set cronjob without removing existing
function setCron () {
	if [ -f $VDMHOME/$ACTION.cron ]; then
		echo "Crontab already configured for updates...Skipping"
	else
		echo -n "Adding crontab entry for continued updates..."
		# check if user crontab is set
		currentCron=$(crontab -u $VDMUSER -l 2>/dev/null)
		if [[ -z "${currentCron// }" ]]; then
			currentCron="# VDM crontab settings"
			echo "$currentCron" > $VDMHOME/$ACTION.cron
		else	
			echo "$currentCron" > $VDMHOME/$ACTION.cron
		fi
		# check if the MAILTO is already set
		if [[ $currentCron != *"MAILTO"* ]]; then
			echo "MAILTO=\"\"" >> $VDMHOME/$ACTION.cron
			echo "" >> $VDMHOME/$ACTION.cron
		fi
		# check if the @reboot curl -s $VDMSCRIPT | sudo bash is already set
		if [[ $currentCron != *"@reboot curl -s $VDMSCRIPT | bash"* ]]; then
			echo "@reboot curl -s $VDMSCRIPT | bash" >> $VDMHOME/$ACTION.cron
		fi
		# check if the @reboot curl -s $VDMSCRIPT | sudo bash is already set
		if [[ $currentCron != *"*/5 * * * * curl -s $VDMSCRIPT | bash"* ]]; then
			echo "*/5 * * * * curl -s $VDMSCRIPT | bash" >> $VDMHOME/$ACTION.cron
		fi
		# set the user cron
		crontab -u $VDMUSER $VDMHOME/$ACTION.cron
		echo "Done"
	fi
}

function getKey () {
	# simple basic random
	echo $(tr -dc 'A-HJ-NP-Za-km-z2-9' < /dev/urandom | dd bs=128 count=1 status=none)
}

function getLocalKey () {
	# Set update key
	if [ -f $VDMHOME/$ACTION.key ]; then
		echo "Update key already set!"
	else
		echo -n "Setting the update key..."
		echo $(getKey) > $VDMHOME/$ACTION.key
		echo "Done"
	fi

	# Get update key
	VDMSERVERKEY=$(<"$VDMHOME/$ACTION.key")
}

function setAccessToken () {
	# check if vdm access was set
	accessToke=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-KEY: $VDMSERVERKEY" --silent $VDMIPSERVER)

	if [[ "$accessToke" != "$TRUE" ]]; then
		read -s -p "Please enter your VDM access key: " vdmAccessKey
		echo ""
		echo -n "One moment while we set your access to the VDM system..."
		resultAccess=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-TRUST: $vdmAccessKey" -H "VDM-KEY: $VDMSERVERKEY" --silent $VDMIPSERVER)
		if [[ "$resultAccess" != "$TRUE" ]]; then
			echo " >> YOUR VDM ACCESS KEY IS INCORRECT! << $resultAccess"
			exit 1
		fi
		echo "Done"
	else
		echo "Access granted to the VDM system."
	fi
}

function setIP () {
	# get this server IP
	IPNOW="$(dig +short myip.opendns.com @resolver1.opendns.com)"
	# store the IP in the HOSTNAME file
	echo -n "Setting/Update the Dynamic IP..."
	resultUpdate=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-KEY: $VDMSERVERKEY" -H "VDM-IP: $IPNOW" --silent $VDMIPSERVER)
	if [[ "$resultUpdate" != "$TRUE" ]]; then
		echo " >> YOUR SERVER KEY IS INCORRECT! << $resultUpdate"
		exit 1
	fi
	echo "Done"
}

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
main 
