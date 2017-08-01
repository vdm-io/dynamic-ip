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
ACTION="getip"
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
	## set time for this run
	echoTweak "$ACTION on $Datetimenow"
	echo "started"
	# get this server IP
	HOSTIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
	## make sure cron is set
	setCron
	## get the local server key
	getLocalKey
	## check access (set if not ready)
	setAccessToken
	## get the IPs
	getIPs
	## check the IPs and then set
	setDNS
}

##############################################################
##############                                      ##########
##############              DEFAULTS                ##########
##############                                      ##########
##############################################################
Datetimenow=$(TZ=":ZULU" date +"%m/%d/%Y @ %R (UTC)" )
VDMUSER=$(whoami)
VDMHOME=~/
VDMSCRIPT="${REPOURL}$ACTION.sh"
VDMSERVERKEY=''
TRUE=1
FALSE=0
HOSTIP=''
THEIPS=''

##############################################################
##############                                      ##########
##############             FUNCTIONS                ##########
##############                                      ##########
##############################################################

# little repeater
function repeat () {
	head -c $1 < /dev/zero | tr '\0' $2
}

# little echo tweak
function echoTweak () {
	echoMessage="$1"
	mainlen="$2"
	characters="$3"
	if [ $# -lt 2 ]
	then
		mainlen=60
	fi
	if [ $# -lt 3 ]
	then
		characters='\056'
	fi
	chrlen="${#echoMessage}"
	increaseBy=$((mainlen-chrlen))
	tweaked=$(repeat "$increaseBy" "$characters")
	echo -n "$echoMessage$tweaked"
}

# Set cronjob without removing existing
function setCron () {
	if [ -f $VDMHOME/$ACTION.cron ]; then
		echoTweak "Crontab already configured for updates..."
		echo "Skipping"
	else
		echoTweak "Adding crontab entry for continued updates..."
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
		if [[ $currentCron != *"* * * * * curl -s $VDMSCRIPT | bash"* ]]; then
			echo "* * * * * curl -s $VDMSCRIPT | bash" >> $VDMHOME/$ACTION.cron
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
		echoTweak "Update key already set!"
		echo "continue"
	else
		echoTweak "Setting the update key..."
		echo $(getKey) > $VDMHOME/$ACTION.key
		echo "Done"
	fi

	# Get update key
	VDMSERVERKEY=$(<"$VDMHOME/$ACTION.key")
}

function setAccessToken () {
	# check if vdm access was set
	accessToke=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-KEY: $VDMSERVERKEY" -H "VDM-HOST-IP: $HOSTIP" --silent $VDMIPSERVER)

	if [[ "$accessToke" != "$TRUE" ]]; then
		read -s -p "Please enter your VDM access key: " vdmAccessKey
		echo ""
		echoTweak "One moment while we set your access to the VDM system..."
		resultAccess=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-TRUST: $vdmAccessKey" -H "VDM-KEY: $VDMSERVERKEY" -H "VDM-HOST-IP: $HOSTIP" --silent $VDMIPSERVER)
		if [[ "$resultAccess" != "$TRUE" ]]; then
			echo "YOUR VDM ACCESS KEY IS INCORRECT! >> $resultAccess"
			exit 1
		fi
		echo "Done"
	else
		echoTweak "Access granted to the VDM system."
		echo "Done"
	fi
}

function getIPs () {
	# store the IP in the HOSTNAME file
	echoTweak "Getting the Dynamic IPs..."
	THEIPS=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "VDM-KEY: $VDMSERVERKEY" -H "VDM-HOST-IP: $HOSTIP"  -H "VDM-GET: 1" --silent $VDMIPSERVER)
	# the IPs
	if [[ "$THEIPS" == "$FALSE" || ${#THEIPS} -lt 15 ]]; then
		echo "No IPs FOUND! "
		exit 1
	fi
	echo "Done"
}

function setDNS () {
	# check IPS
	readarray -t rows <<< "$THEIPS"
	for rr in "${rows[@]}" ; do
		row=( $rr )
		if [[ ${#row[@]} == 3 ]]; then
			# first check IP
			echoTweak "Checking the Dynamic IP..."
			if [[ "${row[2]}" =~ ^([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})$ ]]
			then
				for (( i=1; i<${#BASH_REMATCH[@]}; ++i ))
				do
					if (( ${BASH_REMATCH[$i]} > 255 )); then
						echo "bad IP"
						continue
					fi
				done
			else
				echo "bad IP"
				continue
			fi
			echo "Done"
			echoTweak "Checking local DNS file..."
			# check if the DNS file is found (CENTOS)
			FILEPATH=0
			if [ -f "/var/named/${row[1]}.${row[0]}.db" ] 
			then
				FILEPATH="/var/named/${row[1]}.${row[0]}.db"
				FILENAME="${row[1]}.${row[0]}"
			elif [ -f "/var/named/${row[0]}.db" ]
			then
				FILEPATH="/var/named/${row[0]}.db"
				FILENAME="${row[0]}"
			fi
			# confirm that it was found
			if [[ "$FILEPATH" == 0 ]]
			then
				echo "not found"
				continue				
			fi
			echo "Done"
			# now add the IP A record if needed
			if grep -Fq "${row[2]}" "$FILEPATH"
			then
				# IP already set
				echoTweak "DNS IP (${row[2]})..."
				echo "already set"
			else
				tmpFile=$(getKey)
				# first remove old IPs
				grep -v "^${row[1]} " "$FILEPATH" > "/tmp/vdm_$tmpFile"
				# start notice
				echoTweak "DNS Adding A Record for IP (${row[2]})"
				echo "started"
				# add new a record to tmp file
				echoTweak "${row[1]}" 16 '\040' >> "/tmp/vdm_$tmpFile"
				echoTweak "1" 8 '\040' >> "/tmp/vdm_$tmpFile"
				echo "IN	A	${row[2]}" >> "/tmp/vdm_$tmpFile"
				# add new a record to zone file
				mv "/tmp/vdm_$tmpFile" "$FILEPATH"
				#remove tmp file
				# rm "/tmp/vdm_$tmpFile"
				# Only reload the rndc if found
				if [ -f "/etc/rndc.conf" ]
				then
					cd /var/named
					echoTweak "reload $FILENAME IN external"
					rndc reload "$FILENAME" IN external 2>/dev/null
					echoTweak "reload $FILENAME IN internal"
					rndc reload "$FILENAME" IN internal 2>/dev/null
					echoTweak "notify $FILENAME IN external"
					rndc notify "$FILENAME" IN external 2>/dev/null
					echoTweak "notify $FILENAME IN internal"
					rndc notify "$FILENAME" IN internal 2>/dev/null
					echoTweak "refresh $FILENAME IN external"
					rndc refresh "$FILENAME" IN external 2>/dev/null
					echoTweak "refresh $FILENAME IN internal"
					rndc refresh "$FILENAME" IN internal 2>/dev/null
					cd ~
				fi
			fi
		fi
	done
}

##############################################################
##############                                      ##########
##############                MAIN                  ##########
##############                                      ##########
##############################################################
main 
