#!/bin/bash

if [ "$MAGENTO_PROD_SSH_HOST" == "" ]; then
    echo "Environment variable MAGENTO_PROD_SSH_HOST not set."
    exit 1
fi

if [ "$MAGENTO_PROD_SSH_USER" == "" ]; then
    echo "Environment variable MAGENTO_PROD_SSH_USER not set."
    exit 1
fi

if [ "$MAGENTO_PROD_SSH_PORT" == "" ]; then
    MAGENTO_PROD_SSH_PORT=22
fi

SSHOPTS=""

if [ "$MAGENTO_PROD_SSH_PORT" != "22" ]; then
    SSHOPTS="$SSHOPTS -p $MAGENTO_PROD_SSH_PORT"
fi

if [ "$MAGENTO_PROD_SSH_IDENTITY" != "" ]; then
    SSHOPTS="$SSHOPTS -i $MAGENTO_PROD_SSH_IDENTITY"
fi

SSHCMD="ssh$SSHOPTS ${MAGENTO_PROD_SSH_USER}@${MAGENTO_PROD_SSH_HOST}"

$SSHCMD
