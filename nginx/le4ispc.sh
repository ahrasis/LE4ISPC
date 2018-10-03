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
# Please modify accordingly for multi server setup

# Backup exisiting ISPConfig ssl file(s)
ispcssl=/usr/local/ispconfig/interface/ssl
lelive=/etc/letsencrypt/live/$(hostname -f)
if [ -e "$ispcssl/ispserver.crt" ] && [ -e "$ispcssl/ispserver.key" ] && [ -d "$lelive" ]; then
	cd $ispcssl
	# Backup ISPConfig SSL files
	if ls ispserver.*.bak 1> /dev/null 2>&1; then rm ispserver.*.bak; fi
	mv ispserver.crt ispserver.crt-$(date +"%y%m%d%H%M%S").bak
	mv ispserver.key ispserver.key-$(date +"%y%m%d%H%M%S").bak
	if [ -e "ispserver.pem" ]; then mv ispserver.pem ispserver.pem-$(date +"%y%m%d%H%M%S").bak; fi

	# Create symlink to LE fullchain and key for ISPConfig
	ln -s $lelive/fullchain.pem ispserver.crt
	ln -s $lelive/privkey.pem ispserver.key

	# Build ispserver.pem file, chmod, then restart it
	cat ispserver.{key,crt} > ispserver.pem
	chmod 600 ispserver.pem
	service nginx restart

	# Backup existing postfix ssl file(s)
	postfix=/etc/postfix
	if [ -d "$postfix" ]; then
		cd $postfix
		if ls smtpd.*.bak 1> /dev/null 2>&1; then rm smtpd.*.bak; fi
		if [ -f "smtpd.cert" ]; then mv smtpd.cert smtpd.cert-$(date +"%y%m%d%H%M%S").bak; fi
		if [ -f "smtpd.key" ]; then mv smtpd.key smtpd.key-$(date +"%y%m%d%H%M%S").bak; fi

		# Create symlink from ISPConfig
		ln -s $ispcssl/ispserver.crt smtpd.cert
		ln -s $ispcssl/ispserver.key smtpd.key
		
		# Restart postfix and dovecot
		service postfix restart
		service dovecot restart
	fi
	
	# Backup existing pure-ftpd ssl file(s), if any
	cd /etc/ssl/private/
	if ls pure-ftpd.pem-*.bak 1> /dev/null 2>&1; then rm pure-ftpd.pem-*.bak; fi
	if [ -f "pure-ftpd.pem" ]; then mv pure-ftpd.pem pure-ftpd.pem-$(date +"%y%m%d%H%M%S").bak; fi
	
	# Create symlink from ISPConfig, chmod, then restart it
	ln -sf $ispcssl/ispserver.pem pure-ftpd.pem
	chmod 600 pure-ftpd.pem
	service pure-ftpd-mysql restart
	
	# Backup existing mysql ssl file(s)
	cd /etc/mysql
	if ls server-*.pem-*.bak 1> /dev/null 2>&1; then rm server-*.pem-*.bak; fi
	if [ -f "server-cert.pem" ]; then mv server-cert.pem server-cert.pem-$(date +"%y%m%d%H%M%S").bak; fi
	if [ -f "server-key.pem" ]; then mv server-key.pem server-key.pem-$(date +"%y%m%d%H%M%S").bak; fi
	
	# Copy from ISPConfig, add settings in /etc/mysql/my.cnf and restart mysql
	scp $ispcssl/ispserver.crt /etc/mysql/server-cert.pem
	scp $ispcssl/ispserver.key /etc/mysql/server-key.pem
	sed -i '/\[mysqld\]/a ssl-cipher=TLSv1.2\nssl-cert=/etc/mysql/server-cert.pem\nssl-key=/etc/mysql/server-key.pem' /etc/mysql/my.cnf
	service mysql restart
	
	# Securing monit
	monit=/etc/monit
	monitrc=$monit/monitrc
	if [ -d "$monit" ] && [ -f "$monitrc" ] ; then
		cd $monit
		sed -i '/PEMFILE/d' $monitrc
		sed -i 's/SSL ENABLE/SSL ENABLE\n    PEMFILE \/etc\/ssl\/private\/pure-ftpd.pem/g' $monitrc
		service monit restart
	fi
	
	# Download auto updater script for LE ispserver.pem & others
	cd /etc/init.d/
	if ls le_ispc_pem.sh-*.bak 1> /dev/null 2>&1; then rm le_ispc_pem.sh-*.bak; fi
	if [ -f "le_ispc_pem.sh" ]; then mv le_ispc_pem.sh le_ispc_pem.sh-$(date +"%y%m%d%H%M%S").bak; fi
	wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le_ispc_pem.sh --no-check-certificate
	chmod +x le_ispc_pem.sh
	
	# Install incron, allow root user
	apt-get install -yqq incron
	iallow=/etc/incron.allow
	if grep -q root "$iallow"; then echo;
	else
		echo "root" >> $iallow
	fi
	
	# Manually create icrontab table for root
	iroot=/var/spool/incron
	cd $iroot
	ibash="/etc/letsencrypt/archive/$(hostname -f)/ IN_CREATE,IN_MODIFY /bin/bash /etc/init.d/le_ispc_pem.sh"
	if [ -f "root" ] && grep -q le_ispc_pem.sh "root"; then sed -i '/le_ispc_pem.sh/d' root; fi
	echo $ibash >> root
	chmod 600 root
	# Restart your webserver again
	service nginx restart

else
	if [ ! -f "$ispcssl/ispserver.crt" ] || [ ! -f "$ispcssl/ispserver.key" ]; then
		echo "You did not enable SSL for ISPConfig server control panel. Please enable it before trying."
	fi
	if [ ! -d "$lelive" ]; then
		echo "You did not have Lets Encrypt SSL certs for your server FQDN. Try again when you have them."
	fi
fi
# End of script
