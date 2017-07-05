Dynamic IP
============
This script will update the VDM system with your dynamic IP. To run this script, use the following command (as root):

First time use to setup permission as root:
```
bash <(wget -O -  https://raw.githubusercontent.com/vdm-io/dynamic-ip/master/setip.sh)
```
Once permission is set:
```
curl -s https://raw.githubusercontent.com/vdm-io/dynamic-ip/master/setip.sh | bash
```

This script performs the following actions:

 * Adds random Host Key.
 * Adds a cron entry to update this file on a scheduled basis.
 * Adds the server IP to VDM system.
