#!/bin/bash


# Check environment variables are set up to connect to prodution server.
if [ "$MAGENTO_PROD_SSH_HOST" == "" -o "$MAGENTO_PROD_SSH_USER" == "" ]; then
    echo "This script uses the following environment variables."
    echo ""
    echo "  MAGENTO_PROD_SSH_USER - username to connect with on production host"
    echo "  MAGENTO_PROD_SSH_HOST - hostname or IP address of production host"
    echo "  MAGENTO_PROD_SSH_PORT (optional) - SSH port number to use if not 22"
    echo "  MAGENTO_PROD_SSH_IDENTITY (optional) - SSH identity file if not ~/.ssh/id_rsa"
    echo "  MAGENTO_PROD_SSH_EMAIL (optional) - Email address for ssh key generation"
    echo ""
    echo "You must set at least the first two variables before running this script."
    echo "For example:"
    echo ""
    echo "export MAGENTO_PROD_SSH_USER=xxx"
    echo "export MAGENTO_PROD_SSH_HOST=1.2.3.4"
    exit 1
fi

# Generate a key if we don't have one already.
if [ ! -f $HOME/.ssh/id_rsa.pub ]; then
    echo "==== No existing SSH key found, generating new key."
    if [ "$MAGENTO_PROD_SSH_EMAIL" == "" ]; then
	echo -n "Enter your email address: "
	read MAGENTO_PROD_SSH_EMAIL
    fi
    ssh-keygen -t rsa -C "$MAGENTO_PROD_SSH_EMAIL" -N "" -f $HOME/.ssh/id_rsa
    echo "Copying public key to production server."
    cat $HOME/.ssh/id_rsa.pub | ssh -oStrictHostKeyChecking=no -i $HOME/.ssh/id_rsa "${MAGENTO_PROD_SSH_USER}@${MAGENTO_PROD_SSH_HOST}" "mkdir -p ~/.ssh; cat >>~/.ssh/authorized_keys"
    if [ "$?" != "0" ]; then
	echo "Failed to copy to production host, discarding generated key."
	rm $HOME/.ssh/id_rsa $HOME/.ssh/id_rsa.pub
	exit 1
    fi
    echo "SSH copied to production. Continuing with installation."
    sleep 2
fi


. /usr/local/bin/m2-common.sh


# Make sure user is in group 'daemon' to avoid file permission issues.
# Otherwise bin/magento will fail to run.
runOnProd "sudo usermod -g daemon bitnami"

# Set up the auth.json file if it does not exist.
# We need 'composer install' to download 'vendor' directory for various
# magento commands to work (like put store into maintenance mode).
runOnProd "
    if [ ! -f /opt/bitnami/apps/magento/htdocs/auth.json ]; then
	exit 1
    fi
"
if [ "$?" == "1" ]; then
    if [ "$MAGENTO_REPO_PUBLIC_KEY" == "" ]; then
	echo -n "Please enter your Magento repo public key: "
	read MAGENTO_REPO_PUBLIC_KEY
    fi
    if [ "$MAGENTO_REPO_PRIVATE_KEY" == "" ]; then
	echo -n "Please enter your Magento repo public key: "
	read MAGENTO_REPO_PRIVATE_KEY
    fi
    echo "{
    \"http-basic\": {
        \"repo.magento.com\": {
            \"username\": \"$MAGENTO_REPO_PUBLIC_KEY\",
            \"password\": \"$MAGENTO_REPO_PRIVATE_KEY\"
        }
    }
}
" | runOnProd "mkdir -p ~/.composer; cat >~/.composer/auth.json"
fi

# Bitnami currently is not using version from "composer create-project"
# which means extensions won't be able to install. So if old style, save
# away code and rebuild the site via composer.
runOnProd "
    if grep -q magento/module-backup /opt/bitnami/apps/magento/htdocs/composer.json ; then
        echo ==== Magento not installed via Composer - re-installing.
	set -x
	sudo composer self-update
        cd /opt/bitnami/apps/magento
        sudo mv htdocs htdocs.bak
        sudo mkdir htdocs
	sudo chown bitnami:daemon htdocs
        cd htdocs
	echo Please be patient. The next step will take some time to complete.
        composer create-project --no-progress --repository-url=https://repo.magento.com/ magento/project-community-edition .
        cp ../htdocs.bak/app/etc/env.php app/etc
        cp ../htdocs.bak/app/etc/config.php app/etc
	sudo chown -R bitnami:daemon .
	sudo chmod +x bin/magento
	sudo chmod -R g+w var pub/static
	sudo rm -rf var/{cache,generation,page_cache}/*
    fi
"

# Install GIT if not already present.
runOnProd "
    if [ -f /usr/bin/git ]; then
	echo ==== GIT is already installed.
    else
	echo ==== Installing GIT.
	sudo apt-get update
	sudo apt-get install -y git
    fi
"

# Commit into GIT if not done so already.
runOnProd "
    cd /opt/bitnami/apps/magento/htdocs
    if [ -d .git ]; then
        echo ==== Magento already committed to GIT.
    else
        echo ==== Committing Magento code to GIT.
	git init
	git config --global user.email bitnami@example.com
	git config --global user.name bitnami
	git add .
	git commit -m \"Initial commit\"
    fi
"

# Check out the code locally.
if [ -d /magento2 -a ! -d /magento/.git ]; then
    echo ==== Checking out files locally.
    git clone "ssh://${MAGENTO_PROD_SSH_USER}@${MAGENTO_PROD_SSH_HOST}/opt/bitnami/apps/magento/htdocs/.git" .
fi

