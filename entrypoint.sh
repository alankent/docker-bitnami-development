#!/bin/bash

# Add environment variables to global bashrc file.
echo "" >> /etc/bash.bashrc
echo "# Production server ssh connection details" >> /etc/bash.bashrc
echo "export MAGENTO_PROD_SSH_USER=$MAGENTO_PROD_SSH_USER" >> /etc/bash.bashrc
echo "export MAGENTO_PROD_SSH_HOST=$MAGENTO_PROD_SSH_HOST" >> /etc/bash.bashrc
echo "export MAGENTO_PROD_SSH_PORT=$MAGENTO_PROD_SSH_PORT" >> /etc/bash.bashrc
echo "export MAGENTO_PROD_SSH_IDENTITY=$MAGENTO_PROD_SSH_IDENTITY" >> /etc/bash.bashrc
echo "export MAGENTO_REPO_PUBLIC_KEY=$MAGENTO_REPO_PUBLIC_KEY" >> /etc/bash.bashrc
echo "export MAGENTO_REPO_PRIVATE_KEY=$MAGENTO_REPO_PRIVATE_KEY" >> /etc/bash.bashrc

# Start up MySQL
/usr/local/bin/m2-mysql-start.sh mysqld

# Start up Samba
if [ "$SAMBA_START" == "1" ]; then
    service samba start
fi

# Start up SSHD (for SFTP access)
/usr/sbin/sshd -D &

# Start Apache
exec apache2-foreground
