# LE4ISPC (Single or Multi Server Setup)
Let's Encrypt With Auto Updater is for ISPConfig 3 (Single or Multi Server Setup) and other services like Postfix+Dovecot, Pure-ftpd, Monit etc. It will automatically create Let's Encrypt for the ISPConfig server hostname FQDN when none exists; and secure its control panel and other services; if they are available and installed.

# HOW-TO MASTER
https://github.com/ahrasis/LE4ISPC/tree/master

# HOW-TO FOR NGINX
https://github.com/ahrasis/LE4ISPC/tree/master/nginx

# HOW-TO FOR APACHE2
In your terminal, in root mode, simply run:
```
cd /etc/ssl
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/apache/le4ispc.sh --no-check-certificate
chmod +x le4ispc.sh
./le4ispc.sh
```

# LICENSE
BSD3
