#!/bin/sh

#
# Codeanywhere.com installation script.
#

BASEURL=https://raw.githubusercontent.com/alankent/docker-bitnami-development/master/bin

cd /usr/local/bin
sudo curl -s -O $BASEURL/m2-common.sh
sudo curl -s -O $BASEURL/m2-push
sudo curl -s -O $BASEURL/m2-pull
sudo curl -s -O $BASEURL/m2-setup
sudo curl -s -O $BASEURL/m2-ssh
sudo chmod +x m2-*

# Create new empty Magento directory tree to do m2-pull from
cd $HOME/workspace
if [ -d magento -a ! -f .ca.deleted ]; then

    # Reclaim the disk space
    rm -rf magento
    # Alternative is to save backup.
    #mv magento magento.ca-original

    mkdir magento
    touch .ca.deleted
fi

cat <<EOF
Please remember to set the following environment variables.

    export MAGENTO_PROD_SSH_USER={cloud-server-username}
    export MAGENTO_PROD_SSH_HOST={cloud-server-ip-address}
    export MAGENTO_HOME=\$HOME/workspace/magento
    export MAGENTO_DB_USER=root
    export MAGENTO_DB_PASSWORD=

Then to complete setup run

    cd ~/workspace/magento 
    m2-pull; sudo chgrp -R www-data app var pub; chmod -R g+ws app var pub

After than use 'm2-pull' to get latest code from production and 'm2-push'
to push local changes to production.
EOF
