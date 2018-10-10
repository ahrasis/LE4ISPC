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

# Determine whether this is a webserver (nginx or apache2) or not
# Then request 'hostname -f' LE SSL certs if its path is missing.
lelive=/etc/letsencrypt/live/$(hostname -f)
if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed") -eq 0 ] && [ $(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
	websvr=0
	if [ ! -d "$lelive" ]; then certbot certonly --authenticator standalone -d $(hostname -f); fi
else
	if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		websvr=nginx
	else
		websvr=apache2
	fi
	if [ ! -d "$lelive" ]; then 
		certbot certonly --authenticator standalone -d $(hostname -f) --pre-hook "service $websvr stop" --post-hook "service $websvr start"
	fi
fi

# Proceed if 'hostname -f' LE SSL certs path exists
if [ -d "$lelive" ]; then

	# Activate SSL for ISPConfig if it is not yet enabled.
	ispv=/etc/$websvr/sites-available/ispconfig.vhost
	if [ -e "$ispv" ] && ! grep -q "ssl on" $ispv; then
		if [[ $websvr = "nginx" ]]; then
			sed -i "s/ssl off/ssl on/g" $ispv
			sed -i "s/#ssl_/ssl_/g" $ispv
		else
			sed -i "s/#SSL/SSL/g" $ispv
			sed -i "s/SSLCACertificateFile/#SSLCACertificateFile/g" $ispv
		fi
	fi
	
	# Delete old then backup existing ispserver ssl files
	ispcbak=/usr/local/ispconfig/interface/ssl/ispserver.*.bak
	ispccrt=/usr/local/ispconfig/interface/ssl/ispserver.crt
	ispckey=/usr/local/ispconfig/interface/ssl/ispserver.key
	ispcpem=/usr/local/ispconfig/interface/ssl/ispserver.pem
	
	if ls $ispcbak 1> /dev/null 2>&1; then rm $ispcbak; fi
	if [ -e "$ispccrt" ]; then mv $ispccrt $ispccrt-$(date +"%y%m%d%H%M%S").bak; fi
	if [ -e "$ispckey" ]; then mv $ispckey $ispckey-$(date +"%y%m%d%H%M%S").bak; fi
	if [ -e "$ispcpem" ]; then mv $ispcpem $ispcpem-$(date +"%y%m%d%H%M%S").bak; fi

	# Create symlink to LE fullchain and key for ISPConfig
	ln -s $lelive/fullchain.pem $ispccrt
	ln -s $lelive/privkey.pem $ispckey

	# Build ispserver.pem file and chmod it
	cat $ispckey $ispccrt > $ispcpem
	chmod 600 $ispcpem

	# Restart webserver if it is a webserver
	if [ $(dpkg-query -W -f='${Status}' $websvr 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		service $websvr restart
	fi
	
	# If installed, delete old then backup existing postfix ssl files
	if [ $(dpkg-query -W -f='${Status}' postfix 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		pfbak=/etc/postfix/smtpd.*.bak
		pfcrt=/etc/postfix/smtpd.cert
		pfkey=/etc/postfix/smtpd.key
		if ls $pfbak 1> /dev/null 2>&1; then rm $pfbak; fi
		if [ -e "$pfcrt" ]; then mv $pfcrt $pfcrt-$(date +"%y%m%d%H%M%S").bak; fi
		if [ -e "$pfkey" ]; then mv $pfkey $pfkey-$(date +"%y%m%d%H%M%S").bak; fi

		# Create symlink from ISPConfig
		ln -s $ispccrt $pfcrt
		ln -s $ispckey $pfkey
		
		# Restart postfix and dovecot
		service postfix restart
		if [ $(dpkg-query -W -f='${Status}' dovecot 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
			service dovecot restart
		fi
	fi
	
	# If installed, delete old then backup existing mysql ssl files
	if [ $(dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -c "ok installed") -eq 1 ] || [ $(dpkg-query -W -f='${Status}' mariadb-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		mbak=/etc/mysql/server-*.pem-*.bak
		mcrt=/etc/mysql/server-cert.pem
		mkey=/etc/mysql/server-key.pem
		mcnf=/etc/mysql/my.cnf
		if ls $mbak 1> /dev/null 2>&1; then rm $mbak; fi
		if [ -e "$mcrt" ]; then mv $mcrt $mcrt-$(date +"%y%m%d%H%M%S").bak; fi
		if [ -e "$mkey" ]; then mv $mkey $mkey-$(date +"%y%m%d%H%M%S").bak; fi
	
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
		pte=/etc/ssl/private
		ftpdpem=$pte/pure-ftpd.pem
		if [ ! -d "$pte" ]; then mkdir $pte; fi
		if ls $ftpdpem-*.bak 1> /dev/null 2>&1; then rm $ftpdpem-*.bak; fi
		if [ -e "$ftpdpem" ]; then mv $ftpdpem $ftpdpem-$(date +"%y%m%d%H%M%S").bak; fi
		
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
			if ! grep -q "$ftpdpem" $monitrc; then
				sed -i '/PEMFILE/d' $monitrc
				sed -i "s@SSL ENABLE@SSL ENABLE\n\tPEMFILE $ftpdpem@" $monitrc
			fi
			service monit restart
		fi
	fi
	
	# Download auto updater script for LE ispserver.pem & others
	leispc=/etc/init.d/le4ispc_pem.sh
	if ls $leispc-*.bak 1> /dev/null 2>&1; then rm $leispc-*.bak; fi
	if [ -e "$leispc" ]; then mv $leispc $leispc-$(date +"%y%m%d%H%M%S").bak; fi
	wget -O $leispc https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/le4ispc_pem.sh --no-check-certificate
	chmod +x $leispc
	
	# Install incron, allow root user
	if [ $(dpkg-query -W -f='${Status}' incron 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		apt-get install -yqq incron
	fi
	iallow=/etc/incron.allow
	if ! grep -q "root" $iallow; then echo "root" >> $iallow; fi
	
	# Manually create icrontab table for root
	iroot=/var/spool/incron/root
	ibash="/etc/letsencrypt/archive/$(hostname -f)/ IN_CREATE, IN_MODIFY /bin/bash /etc/init.d/le4ispc_pem.sh"
	if [ -e "$iroot" ] && grep -q "le_ispc_pem.sh" $iroot; then sed -i '/le_ispc_pem.sh/d' $iroot; fi
	echo $ibash >> $iroot
	chmod 600 $iroot
	service incron restart
	
	# Restart webserver if it is a webserver
	if [ $(dpkg-query -W -f='${Status}' $websvr 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
		service $websvr restart
	fi
	
fi
# End of script
