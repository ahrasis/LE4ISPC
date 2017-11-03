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
# set -e
# Backup exisiting ISPConfig ssl file(s)
cd /usr/local/ispconfig/interface/ssl/
mv ispserver.crt ispserver.crt-$(date +"%y%m%d%H%M%S").bak
mv ispserver.key ispserver.key-$(date +"%y%m%d%H%M%S").bak
# If ispserver.pem exists then back it up too
if [ -f "ispserver.pem" ]
then
	mv ispserver.pem ispserver.pem-$(date +"%y%m%d%H%M%S").bak
fi
# Create symlink to LE fullchain and key for ISPConfig
ln -s /etc/letsencrypt/live/$(hostname -f)/fullchain.pem ispserver.crt
ln -s /etc/letsencrypt/live/$(hostname -f)/privkey.pem ispserver.key
# Build ispserver.pem file and chmod it
cat ispserver.{key,crt} > ispserver.pem
chmod 600 ispserver.pem
service nginx restart
# Backup existing postfic ssl file(s)
cd /etc/postfix/
mv smtpd.cert smtpd.cert-$(date +"%y%m%d%H%M%S").bak
mv smtpd.key smtpd.key-$(date +"%y%m%d%H%M%S").bak
# Create symlink from ISPConfig then restart postfix and dovecot
ln -s /usr/local/ispconfig/interface/ssl/ispserver.crt smtpd.cert
ln -s /usr/local/ispconfig/interface/ssl/ispserver.key smtpd.key
service postfix restart
service dovecot restart
# Backup existing pure-ftpd ssl file(s)
cd /etc/ssl/private/
if [ -f "pure-ftpd.pem" ]
then
	mv pure-ftpd.pem pure-ftpd.pem-$(date +"%y%m%d%H%M%S").bak
fi
# Create symlink from ISPConfig, chmod it, then restart it
ln -s /usr/local/ispconfig/interface/ssl/ispserver.pem pure-ftpd.pem
chmod 600 pure-ftpd.pem
service pure-ftpd-mysql restart
# Create auto updater script for LE ispserver.pem
cd /etc/init.d/
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le_ispc_pem.sh
chmod +x le_ispc_pem.sh
# Install incron, allow root user
apt-get install -yqq incron
echo "root" > /etc/incron.allow
# Create icrontab table for root
cd /var/spool/incron/
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/root
chmod 600 root
# Restart your webserver again
service nginx restart
# End of script
