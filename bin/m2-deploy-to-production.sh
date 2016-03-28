#!/bin/bash


. /usr/local/bin/m2-common.sh


echo ==== Committing latest code in development.
git add .
git commit -m "Deployment to production `date`"
git push

echo ==== Put production store into mainenance mode.
runOnProd "magento maintenance:enable true"

echo ==== Pull code on production.
runOnProd "cd apps/magento/htdocs; git pull"

echo ==== Refresh any composer installed libraries.
runOnProd "
    cd /apps/magento/htdocs
    mv composer.json composer.json.original
    sed <composer.json.original >composer.json -e '/extra.: {/ a\
        \"magento-deploystrategy\": \"none\",
'
    composer install
    mv composer.json.original composer.json
"

echo ==== Update the database schema.
runOnProd "magento setup:upgrade"

echo ==== Switching production mode, triggering compile and content deployment.
runOnProd "magento deploy:mode:set production"

#echo ==== Copying compiled asset files to the computer.
#echo ${SCPCMD} index.php ${SCPOPTS}:apps/magento/htdocs

# TODO: Want to make sure this does not run compiler in production!
#echo TODO: ==== Putting production server into production mode.
#echo TODO: runOnProd XXX

#echo ==== Put production store into mainenance mode.
#runOnProd "magento maintenance:enable false"

echo ==== Ready for use.
