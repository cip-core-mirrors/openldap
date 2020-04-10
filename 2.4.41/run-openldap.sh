#!/bin/bash

# Reduce maximum number of number of open file descriptors to 1024
# otherwise slapd consumes two orders of magnitude more of RAM
# see https://github.com/docker/docker/issues/8231
ulimit -n 1024

OPENLDAP_DEBUG_LEVEL=${OPENLDAP_DEBUG_LEVEL:-256}
OPENLDAP_LISTEN_URIS=${OPENLDAP_LISTEN_URIS:-"ldaps:/// ldap:///"}

# Only run if no config has happened fully before
if [ ! -f /etc/openldap/CONFIGURED ]; then

    user=`id | grep -Po "(?<=uid=)\d+"`
    if (( user == 0 ))
    then
        ./run-update-ldap-param.sh
    else
        if [ -f /opt/openldap/etc/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif ]
        then
            # Use provided default config, get rid of current data
            rm -rf /var/lib/ldap/*
            rm -rf /etc/openldap/*
            # Bring in associated default database files
            mv -f /opt/openldap/lib/* /var/lib/ldap
            mv -f /opt/openldap/etc/* /etc/openldap
        else
            # Something has gone wrong with our image build
            echo "FAILURE: Default configuration files from /contrib/ are not present in the image at /opt/openshift."
            exit 1
        fi
    fi

     # Test configuration files, log checksum errors. Errors may be tolerated and repaired by slapd so don't exit
    LOG=`slaptest 2>&1`
    CHECKSUM_ERR=$(echo "${LOG}" | grep -Po "(?<=ldif_read_file: checksum error on \").+(?=\")")
    for err in $CHECKSUM_ERR
    do
        echo "The file ${err} has a checksum error. Ensure that this file is not edited manually, or re-calculate the checksum."
    done

    touch /etc/openldap/CONFIGURED
fi

# Start the slapd service
exec slapd -h "${OPENLDAP_LISTEN_URIS}" -d $OPENLDAP_DEBUG_LEVEL
