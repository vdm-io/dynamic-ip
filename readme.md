Dynamic IP
============
This script will update the VDM system with your dynamic IP. To run this script, use the following command (as root):

*setip* = set IP to VDM system
*getip* = will return all details related to this server

# to set IP:
```
bash <(curl -s https://raw.githubusercontent.com/vdm-io/dynamic-ip/master/setip.sh)
```
This script performs the following actions:

 * Adds random Host Key.
 * Adds a cron entry to update this file on a scheduled basis.
 * Adds the server IP to VDM system.

# to get IPs:
```
bash <(curl -s https://raw.githubusercontent.com/vdm-io/dynamic-ip/master/getip.sh)
```

This script performs the following actions:

 * Adds random Host Key.
 * Adds a cron entry to update this file on a scheduled basis.
 * Gets dynamic IPS for this serves DNS.
