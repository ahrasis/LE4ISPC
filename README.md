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
For multi server setup, you also should have read [the said post (#203)](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-11#post-368888) and modified le_ispc_pem.sh in the main server adding the scp for LE SSL certs and the relevant le4ispc.sh before running it in other servers (i.e. server(s) other than the master server).

# HOW-TO FOR NGINX
In your terminal, in root mode, run:
```
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le4ispc.sh
chmod +x le4ispc.sh
```

# HOW-TO FOR APACHE2
In your terminal, in root mode, run:
```
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/apache/le4ispc.sh
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


# OTHER METHOD
If you have ISPConfig SSL enabled via its installation or update, you may try another way to achieve the same result.

Firstly, when you already have your ISPConfig installed and running, simply check and run these commands in its terminal:
```
# Basically you need incron or something similar
apt install -y incron
# Then allow root user to run it
echo "root" >> /etc/incron.allow
# We need to keep the LE4ISPC script somewhere so...
cd /usr/local/ispconfig/server/scripts
# Change nginx to apache if you use the later
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/nginx/le4ispc.sh
# Make it executable
chmod +x le4ispc.sh
# Make the LE4ISPC script run if your server LE folder is created
echo "/etc/letsencrypt/archive/$(hostname -f)/ IN_CREATE /bin/bash /usr/local/ispconfig/server/scripts/le4ispc.sh" >> /var/spool/incron/root
#That is from the command line
```
Secondly, once you have finished running the above, in ISPConfig control panel (8080), simply create a website under your server FQDN name like server1.domain.tld (this value must be the same as $(hostname -f) output in its terminal).

Thirdly, when it is successfully created, request Let's Encrypt SSL certs by ticking its box.

Once LE SSL certs are issued by Let's Encrypt authority, your ISPConfig control panel (8080) should then have proper certs automatically. However, if they are not not issued by LE Authority, you should then check your LE logs and fix whatever errors that were reported.

So long it is not removed, the LE4ISPC script will be waiting and will do its job after you have fixed the errors. :D


# LICENSE
BSD3
