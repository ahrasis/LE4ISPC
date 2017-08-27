# LE4ISPC
Let's Encrypt for ISPConfig 3, Postfix+Dovecot, Pure-ftpd With Auto Updater for ispserver.pem.

# IMPORTANT! 
Before proceeding, you should already have:
1. ISPConfig SSL enabled via its installation or update; 
2. Created the website for your server via ISPConfig;
3. The said website properly accessible from the internet. 

# HOW-TO FOR NGINX
In your terminal, in root mode, run:
```
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le4ispc.sh
chmod +x le4ispc.sh
./le4ispc.sh
```

# HOW-TO FOR APACHE2
In your terminal, in root mode, run:
```
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/apache/le4ispc.sh
chmod +x le4ispc.sh
./le4ispc.sh
```

# LICENSE
BSD3
