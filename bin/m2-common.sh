#
# Abort if required environment variables are not set
#
function checkEnvironmentVariablesSet () {
    FAIL=0

    if [ "$MAGENTO_PROD_SSH_HOST" == "" ]; then
	echo "Environment variable MAGENTO_PROD_SSH_HOST not set."
	FAIL=1
    fi

    if [ "$MAGENTO_PROD_SSH_USER" == "" ]; then
	echo "Environment variable MAGENTO_PROD_SSH_USER not set."
	FAIL=1
    fi

    if [ "$FAIL" == "1" ]; then
	if [ "$MAGENTO_PROD_SSH_PORT" == "" ]; then
	    echo "Optional environment variable MAGENTO_PROD_SSH_PORT is not set"
	fi
	if [ "$MAGENTO_PROD_SSH_IDENTITY" == "" ]; then
	    echo "Optional environment variable MAGENTO_PROD_SSH_IDENTITY is not set"
	fi
	if [ "$MAGENTO_PROD_SSH_EMAIL" == "" ]; then
	    echo "Optional environment variable MAGENTO_PROD_SSH_EMAIL is not set"
	fi
	echo "Exiting with error status."
	exit 1
    fi

    if [ "$MAGENTO_PROD_SSH_PORT" == "" ]; then
	MAGENTO_PROD_SSH_PORT=22
    fi

    # MAGENTO_PROD_SSH_IDENTITY is optional, no default.

    SSHOPTS=""
    SCPOPTS=""
    if [ "${MAGENTO_PROD_SSH_PORT}" != "22" ]; then
	SSHOPTS="$SSHOPTS -p ${MAGENTO_PROD_SSH_PORT}"
	SCPOPTS="$SCPOPTS -P ${MAGENTO_PROD_SSH_PORT}"
    fi
    if [ "${MAGENTO_PROD_SSH_IDENTITY}" != "" ]; then
        SSHOPTS="$SSHOPTS -i ${MAGENTO_PROD_SSH_IDENTITY}"
        SCPOPTS="$SCPOPTS -i ${MAGENTO_PROD_SSH_IDENTITY}"
    fi
    SSHCMD="ssh${SSHOPTS} ${MAGENTO_PROD_SSH_USER}@${MAGENTO_PROD_SSH_HOST}"
    SCPCMD="scp${SSHOPTS}"
    SCPPROD="${MAGENTO_PROD_SSH_USER}@${MAGENTO_PROD_SSH_HOST}"

    if [ "$SSHOPTS" != "" ]; then
        export GIT_SSH_COMMAND="ssh$SSHOPTS"
    fi
}


#
# Run given command using SSH to the production host.
#
function runOnProd () {
    ${SSHCMD} "sh -c '$*'"
}


checkEnvironmentVariablesSet

# Make sure we can run commands remotely successfully
runOnProd true
if [ "$?" != "0" ]; then
    echo "Failed to execute SSH command on production server."
    exit 1
fi


# We can only run inside docker container with /magento2 present.
if [ ! -d /magento2 ]; then
    echo "/magento2 not found, aborting."
    exit 1
fi
cd /magento2


