#!/bin/bash

# Start up MySQL
/usr/local/bin/m2-mysql-start.sh

# Start up Samba
if [ "$SAMBA_START" == "1" ]; then
    service samba start
fi

# Start up SSHD (for SFTP access)
/usr/sbin/sshd -D &

# Start Apache
exec apache2-foreground
