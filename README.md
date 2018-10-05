# LE4ISPC (Single or Multi Server Setup)
Let's Encrypt With Auto Updater is for ISPConfig 3 (Single or Multi Server Setup) and other services like Postfix+Dovecot, Pure-ftpd, Monit etc.

# IMPORTANT! 
Before proceeding, you should already have LE SSL certs successfully created for your ISPConfig server fqdn i.e. the paths to and the certs in e.g. /etc/letsencrypt/archive/server.domain.tld, /etc/letsencrypt/live/server.domain.tld must already exist.

# HOW-TO FOR NGINX
In your terminal, in root mode, run:
```
cd /etc/ssl
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le4ispc.sh --no-check-certificate
chmod +x le4ispc.sh
./le4ispc.sh
```

# HOW-TO FOR APACHE2
In your terminal, in root mode, run:
```
cd /etc/ssl
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/apache/le4ispc.sh --no-check-certificate
chmod +x le4ispc.sh
./le4ispc.sh
```

# HOW-TO OTHER METHOD
In reverse, before you obtained the certs, you can also run the commands below (to install incron, allow root to run incron, download the le4ispc.sh script from this github, make the script executable and create an incron job to run the script upon your server Let's Encrypt archive folder is created):
```
apt install -y incron
echo "root" >> /etc/incron.allow
cd /etc/ssl
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le4ispc.sh --no-check-certificate
chmod +x le4ispc.sh
echo "/etc/letsencrypt/live/$(hostname -f)/ IN_CREATE /bin/bash /etc/ssl/le4ispc.sh" >> /var/spool/incron/root
```
The LE4ISPC script will be waiting for the certs to be created and will run after the certs are issued. ;D

# STANDALONE LET'S ENCRYPT
I haven't tested this but if you do not have the above certs yet, using latest certbot client, you can manually run one of the following standalone command to issue them:
``` 
# For Nginx web server, try:
certbot certonly --authenticator standalone -d server.domain.tld --pre-hook 'service stop nginx' --post-hook 'service start nginx'

# For Apache2 web server, try:
certbot certonly --authenticator standalone -d server.domain.tld --pre-hook 'service stop apache2' --post-hook 'service start apache2'

# For other server, try:
certbot certonly --authenticator standalone -d server.domain.tld
```
I will integrate this once the above command is successfully tested.

# WEBROOT LET'S ENCRYPT
Other then the above standalone way, for multi server setup under LAN (not WAN), you should read [the said post #203](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-11#post-368888) and modify le_ispc_pem.sh in the main server adding the scp for LE SSL certs and the relevant le4ispc.sh accordingly before running it in other servers (i.e. server(s) other than the master server).

# WEBROOT LET'S ENCRYPT CHANGES EXAMPLES
1. For multi server setup, do read [post (#203)](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-11#post-368888).
2. Basically, in the main server, add scp -r /etc/letsencrypt/ root@otherserverip:/etc/ at the end of le_ispc_pem.sh. This is to automate future scp of updated LE SSL certs to the other server as specied.
3. Copy, modify and add more line, if you need to scp to more than one server.
4. Add -P XX (where xx is port number) after scp if you change your default ssh port from 22 to other number.
5. In the other server(s), do change $(hostname -f) to the main server hostname / domain in "root" and "le4ispc.sh" file. You may also remove other services that you may not need for specific server.
6. Securing mysql server is now covered by the script. In case you need explanation or to secure your mysql server manually do read [post #247](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-13#post-376720)
7. Simply scp ispconfig ssl files (crt and key) to your /etc/mysql folder and then enable ssl for mysql by modifying / adding their settings in /etc/mysql/my.cnf file.

# WEBROOT LET'S ENCRYPT DO AND DO NOT
Please DO modify le_ispc_pem.sh in /etc/init.d/ folder to enable support for multi server setup but DO NOT delete it or your ispconfig.pem (which is required / needed by some other services via symlinks) will fail.

# LICENSE
BSD3
