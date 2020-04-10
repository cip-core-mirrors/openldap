FROM centos:centos7

USER root

LABEL io.k8s.description="OpenLDAP is an open source implementation of the Lightweight Directory Access Protocol." \
      io.k8s.display-name="OpenLDAP 2.4.41" \
      io.openshift.expose-services="389:ldap,636:ldaps" \
      io.openshift.tags="directory,ldap,openldap,openldap2441" \
      io.openshift.non-scalable="true"

# Add startup scripts
COPY run-*.sh /usr/local/bin/
COPY contrib/*.ldif /usr/local/etc/openldap/
COPY contrib/*.schema /usr/local/etc/openldap/
COPY contrib/DB_CONFIG /usr/local/etc/openldap/

# Install OpenLDAP Server, give it permissionst to bind to low ports
RUN yum install -y openldap openldap-servers openldap-clients && \
    yum clean all -y && \
    chmod -R +x /usr/local/bin /usr/local/etc/openldap/ && \
    setcap 'cap_net_bind_service=+ep' /usr/sbin/slapd

WORKDIR /usr/local/bin

# Run update LDAP config script
RUN ./run-update-ldap-param.sh && \
    mkdir -p /opt/openldap/lib && \
    mkdir -p /opt/openldap/etc && \
    chgrp -R 0 /etc/openldap /var/lib/ldap /var/run/openldap /opt/openldap && \
    chmod g=u -R /etc/openldap /var/lib/ldap /var/run/openldap /opt/openldap  && \
    mv -f /var/lib/ldap/* /opt/openldap/lib && \
    mv -f /etc/openldap/* /opt/openldap/etc

USER 1001

# Set OpenLDAP data and config directories in a data volume
VOLUME ["/var/lib/ldap", "/etc/openldap"]

# Expose default ports for ldap and ldaps
EXPOSE 389 636

CMD ["/usr/local/bin/run-openldap.sh"]
