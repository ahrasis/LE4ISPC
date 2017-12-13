# LE4ISPC
Let's Encrypt for ISPConfig 3, Postfix+Dovecot, Pure-ftpd With Auto Updater for ispserver.pem. This can also be used in multi server setup [as described in post #203 of the related forum](https://www.howtoforge.com/community/threads/securing-ispconfig-3-control-panel-port-8080-with-lets-encrypt-free-ssl.75554/page-11#post-368888) by modifying le_ispc_pem.sh in the main server and le4ispc.sh on other servers.

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

Execute as follows only after you have made necessary changes especially for ISPConfig multi server setup. 
```
./le4ispc.sh
```

# HOW-TO FOR APACHE2
In your terminal, in root mode, run:
```
wget https://raw.githubusercontent.com/ahrasis/LE4ISPC/master/apache/le4ispc.sh
chmod +x le4ispc.sh
./le4ispc.sh
```

Execute as follows only after you have made necessary changes especially for ISPConfig multi server setup.
```
./le4ispc.sh
```

# LICENSE
BSD3
