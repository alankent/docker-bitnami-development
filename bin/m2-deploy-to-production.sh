#!/bin/bash


. /usr/local/bin/m2-common.sh


echo ==== Committing latest code in development.
git add .
git commit -m \"Pushing to prod `date`\"
git push

echo ==== Switching development mode to production mode, triggering compile.
magento deploy:mode:set production

echo ==== Put production store into mainenance mode.
runOnProd "magento maintenance:enable true"

echo ==== Pull code on production.
runOnProd "cd apps/magento/htdocs; git pull"

echo ==== Copying compiled asset files to the computer.
echo ${SCPCMD} index.php ${SCPOPTS}:apps/magento/htdocs

# TODO: Want to make sure this does not run compiler in production!
echo TODO: ==== Putting production server into production mode.
echo TODO: runOnProd XXX

echo ==== Update the database schema.
runOnProd "magento setup:upgrade"

echo ==== Put production store into mainenance mode.
runOnProd "magento maintenance:enable false"

echo ==== Ready for use.
