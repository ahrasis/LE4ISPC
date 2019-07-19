#!/bin/sh
### BEGIN INIT INFO
# Provides:  LE ISPSERVER.PEM AUTO UPDATER
# Required-Start:  $local_fs $network
# Required-Stop:  $local_fs
# Default-Start:  2 3 4 5
# Default-Stop:  0 1 6
# Short-Description:  LE ISPSERVER.PEM AUTO UPDATER
# Description:  Update ispserver.pem automatically after ISPC LE SSL certs are renewed.
### END INIT INFO
# Enable set -e to cause script to exit on error
# Recreate pem file if letsencrypt ssl certs exist
# then restart all available service(s)
set -e
lelive=/etc/letsencrypt/live/$(hostname -f); if [ -d "$lelive" ]; then
  cd /usr/local/ispconfig/interface/ssl; ibak=ispserver.*.bak; ipem=ispserver.pem; icrt=ispserver.crt; ikey=ispserver.key
  if ls $ibak 1> /dev/null 2>&1; then rm $ibak; fi
  if [ -e "$ipem" ]; then mv $ipem $ipem-$(date +"%y%m%d%H%M%S").bak; cat $ikey $icrt > $ipem; chmod 600 $ipem; fi
  pureftpdpem=/etc/ssl/private/pure-ftpd.pem; if [ -e "$pureftpdpem" ]; then chmod 600 $pureftpdpem; fi
  if [ $(dpkg-query -W -f='${Status}' pure-ftpd-mysql 2>/dev/null | grep -c "ok installed") -eq 1 ]; then service pure-ftpd-mysql restart; fi
  if [ $(dpkg-query -W -f='${Status}' monit 2>/dev/null | grep -c "ok installed") -eq 1 ]; then service monit restart; fi
  if [ $(dpkg-query -W -f='${Status}' postfix 2>/dev/null | grep -c "ok installed") -eq 1 ]; then service postfix restart; fi
  if [ $(dpkg-query -W -f='${Status}' dovecot-imapd 2>/dev/null | grep -c "ok installed") -eq 1 ]; then service dovecot restart; fi
  if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed") -eq 1 ]; then service nginx restart; fi
  if [ $(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c "ok installed") -eq 1 ]; then service apache2 restart; fi
else echo "Your Lets Encrypt SSL certs path for your ISPConfig server FQDN is missing."; fi
# Let's Encrypt will not work for mysql, so the related code were removed.
# The whole code is shorten simplified whenever possile.
