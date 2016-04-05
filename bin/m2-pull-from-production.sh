#!/bin/bash


# Make sure things are set up (this is safe to run multiple times)
if [ ! -f /production-initialized ]; then
    /usr/local/bin/m2-production-initial-setup.sh
    if [ "$?" != "0" ]; then
	exit 1
    fi
    sudo touch /production-initialized
fi


# Load common rules.
. /usr/local/bin/m2-common.sh


echo ==== Committing latest code from production.
runOnProd "
    cd /opt/bitnami/apps/magento/htdocs
    git add .
    git commit -m \"Pulling to dev `date`\"
    git push upstream master
"

echo ==== Retrieving code from production to dev.
git pull
mkdir -p pub/static app/etc pub/media pub/opt

echo ==== Downloading any next patches or extensions.
# Tell composer not to override local changes.
# Eventually this step will not be required.
mv composer.json composer.json.original
sed -e '/extra.: {/ a\
        \"magento-deploystrategy\": \"none\",
' <composer.json.original >composer.json
composer install
mv composer.json.original composer.json

# If first time install, we need to do a few extra steps.
if [ ! -f /magento2/app/etc/env.php ]; then
    chmod +x bin/magento

    # Create config.php, env.php, create database, etc
    magento setup:install --backend-frontname=admin \
	--cleanup-database --db-host=127.0.0.1 \
	--db-name=magento --db-user=magento --db-password=magento \
	--admin-firstname=Magento --admin-lastname=User \
	--admin-email=user@example.com \
	--admin-user=admin --admin-password=admin123 --language=en_US \
	--currency=USD --timezone=America/Chicago --use-rewrites=1

    # Set developer mode
    magento deploy:mode:set developer

fi

echo ==== Clearing development caches.
magento cache:clean

echo ==== Upgrade database schema to new schema.
magento setup:upgrade

echo ==== Rebuilding indexes to reduce warnings about old indexes at startup.
magento indexer:reindex

echo ==== Switching store live locally.
magento maintenance:disable

# Above commands result in 'localhost' being in cached files - clear
# the cache to lose that setting.
rm -rf var/cache

echo ==== Ready for use.
