#!/bin/bash


. /usr/local/bin/m2-common.sh


HTDOCS=/opt/bitnami/apps/magento/htdocs


echo ==== Committing latest code in development.
git config user.email "$USER@example.com"
git config user.name "$USER"
git config push.default simple
git add .
git commit -m "Deployment to production `date`"
git push origin master

echo ==== Put production store into mainenance mode.
runOnProd "
    cd $HTDOCS
    bin/magento maintenance:enable
"

echo ==== Merge development changes on production.
runOnProd "
    cd $HTDOCS
    git pull upstream master
"

echo ==== Refresh any composer installed libraries.
# This turns off the Magento installer installing 'base' package changes
# over the top of any locally committed changes. Eventually this will
# no longer be required. For now, do not do this in production.
runOnProd "
    cd $HTDOCS
    mv composer.json composer.json.original
    sed <composer.json.original >composer.json -e \"/extra.:/ a\\
        \"magento-deploystrategy\": \"none\",
\"
    composer install
    mv composer.json.original composer.json
"

echo ==== Update the database schema.
runOnProd "
    cd $HTDOCS
    bin/magento setup:upgrade
"

echo ==== Turning off bitnami banner
runOnProd "
    sudo /opt/bitnami/apps/magento/bnconfig --disable_banner 1
    sudo /opt/bitnami/ctlscript.sh restart apache
"

echo ==== Switching production mode, triggering compile and content deployment.
runOnProd "
    cd $HTDOCS
    bin/magento deploy:mode:set production
"

echo ==== Ready for use.
