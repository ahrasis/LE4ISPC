# LE4ISPC (Single or Multi Server Setup)
Let's Encrypt With Auto Updater is for ISPConfig 3 (Single or Multi Server Setup) and other services like Postfix+Dovecot, Pure-ftpd, Monit etc.

# IMPORTANT! 
Before proceeding, you should have followed step 1-5 [at HowToForge](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/) and should already have:
```
1. ISPConfig SSL enabled via its installation or update; 
2. Created the website for your server via ISPConfig;
3. The said website properly accessible from the internet;
4. LE SSL successfully enabled for it.
```

# REMEMBER!
For multi server setup, you also should have read [the said post #203](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-11#post-368888) and modified le_ispc_pem.sh in the main server adding the scp for LE SSL certs and the relevant le4ispc.sh before running it in other servers (i.e. server(s) other than the master server).

# HOW-TO FOR NGINX
In your terminal, in root mode, run:
```
cd /tmp
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le4ispc.sh --no-check-certificate
chmod +x le4ispc.sh
```

# HOW-TO FOR APACHE2
In your terminal, in root mode, run:
```
cd /tmp
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/apache/le4ispc.sh --no-check-certificate
chmod +x le4ispc.sh
```

# RUNNING THE SCRIPT
If you do not have run ISPConfig multi server setup, you may continue to run this in your terminal without making any changes.
```
./le4ispc.sh
```

# CHANGES EXAMPLES
1. For multi server setup, do read [post (#203)](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-11#post-368888).
2. Basically, in the main server, add scp -r /etc/letsencrypt/ root@otherserverip:/etc/ at the end of le_ispc_pem.sh. This is to automate future scp of updated LE SSL certs to the other server as specied.
3. Copy, modify and add more line, if you need to scp to more than one server.
4. Add -P XX (where xx is port number) after scp if you change your default ssh port from 22 to other number.
5. In the other server(s), do change $(hostname -f) to the main server hostname / domain in "root" and "le4ispc.sh" file. You may also remove other services that you may not need for specific server.
6. Securing mysql server is now covered by the script. In case you need explanation or to secure your mysql server manually do read [post #247](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-13#post-376720)
7. Simply scp ispconfig ssl files (crt and key) to your /etc/mysql folder and then enable ssl for mysql by modifying / adding their settings in /etc/mysql/my.cnf file.

# DO AND DO NOT
Please DO modify le_ispc_pem.sh in /etc/init.d/ folder to enable support for multi server setup but DO NOT delete it or your ispconfig.pem (which is required / needed by some other services via symlinks) will fail.


# OTHER METHOD
Step 1
Ensure your ISPConfig server is SSL enabled by viewing it in a web browser e.g. https://yourserver1.domain.tld. Normally the browser will show a warning for using self-signed SSL certs created while installing your server.

Step 2
Run the commands below (to install incron, allow root to run incron, download the le4ispc.sh script from this github, make the script executable and create an incron job to run the script upon your server Let's Encrypt archive folder is created):
```
apt install -y incron
echo "root" >> /etc/incron.allow
cd /usr/local/ispconfig/server/scripts
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le4ispc.sh --no-check-certificate
chmod +x le4ispc.sh
echo "/etc/letsencrypt/archive/$(hostname -f)/ IN_CREATE /bin/bash /usr/local/ispconfig/server/scripts/le4ispc.sh" >> /var/spool/incron/root
```
Step 3
When you finished with the above, access your ISPConfig control panel and create a website under your server FQDN name e.g. server1.domain.tld. It is important to note that this value must be the same as $(hostname -f) output.

Step 4
When the website has been created, request Let's Encrypt SSL certs by ticking its box and wait for it to be successfully issued (as once LE SSL certs are issued by Let's Encrypt authority, your ISPConfig control panel (8080) should have the proper LE SSL certs automatically applied to it).

However, if they are not not issued by LE Authority, you should then check your LE logs and fix whatever errors that were reported.

So long it is not removed, the LE4ISPC script will be waiting and will do its job after you have fixed the errors. ;D


# LICENSE
BSD3
