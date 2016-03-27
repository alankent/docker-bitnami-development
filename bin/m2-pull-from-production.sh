#!/bin/bash


. /usr/local/bin/m2-common.sh


echo ==== Committing latest code from production.
runOnProd "
    cd /opt/bitnami/apps/magento/htdocs
    git config user.email $USER@example.com
    git config user.name $USER
    git add .
    git commit -m \"Pulling to dev `date`\"
"

echo ==== Switching store to maintenance mode locally.
magento maintenance:enable

echo ==== Retrieving code from production to dev.
git pull

echo ==== Clearing development caches.
magento cache:clean

echo ==== Downloading any next patches or extensions.
composer install

echo ==== Upgrade database schema to new schema.
magento setup:upgrade

echo ==== Switching store live locally.
magento maintenance:disable

echo ==== Ready for use.
