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
set -e

# Check the letsencrypt ssl certs path
# then recreate pem file and finally  
# restart all relevant service(s)
lelive=/etc/letsencrypt/live/$(hostname -f)
if [ -d "$lelive" ]; then
	if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		websvr=nginx
	else
		websvr=apache2
	fi
	cd /usr/local/ispconfig/interface/ssl
	ispcbak=ispserver.*.bak
	ispccrt=ispserver.crt
	ispckey=ispserver.key
	ispcpem=ispserver.pem
	if ls $ispcbak 1> /dev/null 2>&1; then rm $ispcbak; fi
	if [ -e "$ispcpem" ]; then mv $ispcpem $ispcpem-$(date +"%y%m%d%H%M%S").bak; fi
	cat $ispckey $ispccrt > $ispcpem
	chmod 600 $ispcpem
	if [ $(dpkg-query -W -f='${Status}' $websvr 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		service $websvr restart
	fi
	if [ $(dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -c "ok installed") -eq 1 ] || [ $(dpkg-query -W -f='${Status}' mariadb-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		scp ispserver.crt /etc/mysql/server-cert.pem
		scp ispserver.key /etc/mysql/server-key.pem
		service mysql restart
	fi
	if [ $(dpkg-query -W -f='${Status}' pure-ftpd-mysql 2>/dev/null | grep -c "ok installed") -eq 1 ] || [ $(dpkg-query -W -f='${Status}' monit 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		chmod 600 /etc/ssl/private/pure-ftpd.pem
		if [ $(dpkg-query -W -f='${Status}' pure-ftpd-mysql 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			service pure-ftpd-mysql restart
		fi
		if [ $(dpkg-query -W -f='${Status}' monit 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			service monit restart
		fi
	fi
	if [ $(dpkg-query -W -f='${Status}' postfix 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		service postfix restart
		service dovecot restart
	fi
	if [ $(dpkg-query -W -f='${Status}' $websvr 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		service $websvr restart
	fi
else
	echo "Your Lets Encrypt SSL certs path for your ISPConfig server FQDN is missing."
fi
