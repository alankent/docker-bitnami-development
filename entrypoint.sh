#!/bin/bash

# Add environment variables to global bashrc file.
cat << EOF >> /etc/bash.bashrc

# Production server ssh connection details
export MAGENTO_PROD_SSH_USER=$MAGENTO_PROD_SSH_USER
export MAGENTO_PROD_SSH_HOST=$MAGENTO_PROD_SSH_HOST
export MAGENTO_PROD_SSH_PORT=$MAGENTO_PROD_SSH_PORT
export MAGENTO_PROD_SSH_IDENTITY=$MAGENTO_PROD_SSH_IDENTITY
export MAGENTO_PROD_SSH_EMAIL=$MAGENTO_PROD_SSH_EMAIL
export MAGENTO_REPO_PUBLIC_KEY=$MAGENTO_REPO_PUBLIC_KEY
export MAGENTO_REPO_PRIVATE_KEY=$MAGENTO_REPO_PRIVATE_KEY

# Make sure 'magento' is in the PATH variable.
export PATH=${PATH}:/opt/bitnami/apps/magento/htdocs/bin

EOF

# Start up MySQL
/usr/local/bin/m2-mysql-start.sh mysqld

# Start up Samba
if [ "$SAMBA_START" == "1" ]; then
    echo Starting Samba.
    echo Mount on Windows using
    echo '  NET USE M: \\192.168.99.100\magento2 magento /USER:magento'
    service samba start
fi

# Start up SSHD (for SFTP access)
/usr/sbin/sshd -D &

# Start Apache
exec apache2-foreground
