#!/bin/sh
### BEGIN INIT INFO
# Provides:  REMOVE MAIN LEFTOVERS FROM LE4ISPC SCRIPTS OR TUTORIAL
# Required-Start:  $local_fs $network
# Required-Stop:  $local_fs
# Default-Start:  2 3 4 5
# Default-Stop:  0 1 6
# Short-Description:  REMOVE MAIN LEFTOVERS FROM LE4ISPC SCRIPTS OR TUTORIAL
# Description:  REMOVE MAIN LEFTOVERS FROM LE4ISPC SCRIPTS OR TUTORIAL
### END INIT INFO

# Enable set -e to cause script to exit on error
set -e

le4ispc=/etc/ssl/le4ispc.sh
if [ -e "$le4ispc" ]; then rm $le4ispc; fi
le4ispc_pem=/etc/init.d/le4ispc_pem.sh
if [ -e "$le4ispc_pem" ]; then rm $le4ispc_pem; fi
le_ispc_pem=/etc/init.d/le_ispc_pem.sh
if [ -e "$le_ispc_pem" ]; then rm $le_ispc_pem; fi

iroot=/var/spool/incron/root
if [ -e "$iroot" ] && grep -q "le4ispc_pem.sh" $iroot; then sed -i '/le4ispc_pem.sh/d' $iroot; fi
if [ -e "$iroot" ] && grep -q "le_ispc_pem.sh" $iroot; then sed -i '/le_ispc_pem.sh/d' $iroot; fi
chmod 600 $iroot
service incron restart

rm -rf /etc/letsencrypt/*/$(hostname -f)*
echo 'Please update to the latest ISPConfig 3.2.* using ispconfig_update.sh --force, backup, reconfigure services and create SSL during the update process.'  
