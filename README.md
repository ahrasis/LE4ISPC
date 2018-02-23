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
2. Basically, in the main server, add scp -r /etc/letsencrypt/live/$(hostname -f)/ root@otherserverip:/etc/letsencrypt/live/ at the end of le_ispc_pem.sh. This is to automate future scp of updated LE SSL certs to the other server as specied. Copy, modify and add more line, if you need to scp to more than one server.
3. In the other server(s), do change $(hostname -f) to the main server hostname / domain in "root" and "le4ispc.sh" file. You may also remove other services that you may not need for specific server.

# LICENSE
BSD3
