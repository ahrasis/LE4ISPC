#!/bin/sh
### BEGIN INIT INFO
# Provides:  CREATE LE SSL FOR ISPC AND OTHER MAIN SERVICES
# Required-Start:  $local_fs $network
# Required-Stop:  $local_fs
# Default-Start:  2 3 4 5
# Default-Stop:  0 1 6
# Short-Description:  CREATE LE SSL FOR ISPC AND OTHER MAIN SERVICES
# Description:  Create LE SSL for ISPC and other main services.
### END INIT INFO

# Enable set -e to cause script to exit on error
set -e

# Check if ISPConfig ssl is on and its LE SSL path exists
lelive=/etc/letsencrypt/live/$(hostname -f)
ispv=/etc/apache2/sites-available/ispconfig.vhost
if grep -q "ssl on" $ispv && [ -d "$lelive" ]; then
	# Delete old then backup existing ispserver ssl files
	ispcssl=/usr/local/ispconfig/interface/ssl
	ispcbak=$ispcssl/ispserver.*.bak
	ispccrt=$ispcssl/ispserver.crt
	ispckey=$ispcssl/ispserver.key
	ispcpem=$ispcssl/ispserver.pem
	if ls $ispcbak 1> /dev/null 2>&1; then rm $ispcbak; fi
	if -e "$ispccrt"; then mv $ispccrt $ispccrt-$(date +"%y%m%d%H%M%S").bak; fi
	if -e "$ispckey"; then mv $ispckey $ispckey-$(date +"%y%m%d%H%M%S").bak; fi
	if -e "$ispcpem"; then mv $ispcpem $ispcpem-$(date +"%y%m%d%H%M%S").bak; fi

	# Create symlink to LE fullchain and key for ISPConfig
	ln -s $lelive/fullchain.pem $ispccrt
	ln -s $lelive/privkey.pem $ispckey

	# Build ispserver.pem file, chmod, then restart it
	cat $ispckey,$ispccrt > $ispcpem
	chmod 600 $ispcpem
	service apache2 restart

	# If installed, delete old then backup existing postfix ssl files
	if [ $(dpkg-query -W -f='${Status}' postfix 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		postfix=/etc/postfix
		cd $postfix
		if ls smtpd.*.bak 1> /dev/null 2>&1; then rm smtpd.*.bak; fi
		if -e "smtpd.cert"; then mv smtpd.cert smtpd.cert-$(date +"%y%m%d%H%M%S").bak; fi
		if -e "smtpd.key"; then mv smtpd.key smtpd.key-$(date +"%y%m%d%H%M%S").bak; fi

		# Create symlink from ISPConfig
		ln -s $ispccrt smtpd.cert
		ln -s $ispckey smtpd.key
		
		# Restart postfix and dovecot
		service postfix restart
		service dovecot restart
	fi
	
	# If installed, delete old then backup existing mysql ssl files
	if [ $(dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -c "ok installed") -eq 1 ] || [ $(dpkg-query -W -f='${Status}' mariadb-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		mbak=/etc/mysql/server-*.pem-*.bak
		mcrt=/etc/mysql/server-cert.pem
		mkey=/etc/mysql/server-key.pem
		mcnf=/etc/mysql/my.cnf
		if ls $mbak 1> /dev/null 2>&1; then rm $mbak; fi
		if -e "$mcrt"; then mv $mcrt $mcrt-$(date +"%y%m%d%H%M%S").bak; fi
		if -e "$mkey"; then mv $mkey $mkey-$(date +"%y%m%d%H%M%S").bak; fi
	
		# Copy from ISPConfig, add settings in /etc/mysql/my.cnf and restart mysql
		scp $ispccrt $mcrt
		scp $ispckey $mkey
		if ! grep -q "$mcrt" $mcnf && ! grep -q "$mkey" $mcnf; then
			sed -i "/\[mysqld\]/a ssl-cipher=TLSv1.2\nssl-cert=$mcrt\nssl-key=$mkey" $mcnf
		fi
		service mysql restart
	fi

	# If installed, delete old then backup existing pure-ftpd.pem file
	if [ $(dpkg-query -W -f='${Status}' pure-ftpd-mysql 2>/dev/null | grep -c "ok installed") -eq 1 ] || [ $(dpkg-query -W -f='${Status}' monit 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		ftpdpem=/etc/ssl/private/pure-ftpd.pem
		if ls $ftpdpem-*.bak 1> /dev/null 2>&1; then rm $ftpdpem-*.bak; fi
		if -e "$ftpdpem"; then mv $ftpdpem $ftpdpem-$(date +"%y%m%d%H%M%S").bak; fi
		
		# Create symlink from ISPConfig, chmod, then restart it
		ln -sf $ispcpem $ftpdpem
		chmod 600 $ftpdpem

		# Restart only if pure-ftpd-mysql is installed
		if [ $(dpkg-query -W -f='${Status}' pure-ftpd-mysql 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			service pure-ftpd-mysql restart
		fi
	
		# Securing monit using pure-ftpd.pem
		if [ $(dpkg-query -W -f='${Status}' monit 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			monitrc=/etc/monit/monitrc
			if grep -q "$ftpdpem" $monitrc; then
				sed -i '/PEMFILE/d' $monitrc
				sed -i "s/SSL ENABLE/SSL ENABLE\n\tPEMFILE $ftpdpem/g" $monitrc
			fi
			service monit restart
		fi
	fi
	
	# Download auto updater script for LE ispserver.pem & others
	leispc=/etc/init.d/le_ispc_pem.sh
	if ls $leispc-*.bak 1> /dev/null 2>&1; then rm $leispc-*.bak; fi
	if -e "$leispc" ]; then mv $leispc $leispc-$(date +"%y%m%d%H%M%S").bak; fi
	wget -O $leispc https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/apache/le_ispc_pem.sh --no-check-certificate
	chmod +x $leispc
	
	# Install incron, allow root user
	apt-get install -yqq incron
	iallow=/etc/incron.allow
	if ! grep -q "root" $iallow; then echo "root" >> $iallow; fi
	
	# Manually create icrontab table for root
	iroot=/var/spool/incron/root
	ibash="/etc/letsencrypt/archive/$(hostname -f)/ IN_CREATE, IN_MODIFY /bin/bash /etc/init.d/le_ispc_pem.sh"
	if [ -e "$iroot" ] && grep -q "le_ispc_pem.sh" $iroot; then sed -i '/le_ispc_pem.sh/d' $iroot; fi
	echo $ibash >> $iroot
	chmod 600 $iroot
	
	# Restart your webserver again
	service apache2 restart

else
	if [ ! -d "$lelive" ]; then
		echo "You did not have Lets Encrypt SSL certs for your server FQDN. Try again when you have them."
	else
		echo "You did not enable SSL for ISPConfig server control panel. Please enable it before trying."
	fi
fi
# End of script
