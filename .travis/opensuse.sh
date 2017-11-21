#!/bin/bash -xe
OS_NAME=$(${DOCKER_EXEC} cat /etc/os-release | awk -F[=\"] '/^NAME=/ {print $3}')
OS_VERSION=$(${DOCKER_EXEC} cat /etc/os-release | awk -F[=\"] '/VERSION=/ {print $3}')
OS_NAME_VERSION=${OS_NAME// /_}_${OS_VERSION// /_}
${DOCKER_EXEC} zypper -n ar -f -G http://download.opensuse.org/repositories/devel:/tools/${OS_NAME_VERSION}/devel:tools.repo
${DOCKER_EXEC} zypper -n ref
${DOCKER_EXEC} zypper -n install rpmdevtools
${DOCKER_EXEC} rpmdev-setuptree
${DOCKER_EXEC} /bin/sh -c "zypper -n install \$(rpmspec --buildrequires -q pbspro.spec)"
${DOCKER_EXEC} ./autogen.sh
if [ ${BUILD_TYPE} == "DEBUG" ]; then
    ${DOCKER_EXEC} ./configure CFLAGS=-DDEBUG \
                               --prefix=/opt/pbs \
                               --with-pbs-server-home=/var/spool/pbs \
                               --with-database-user=postgres 
    ${DOCKER_EXEC} make
    ${DOCKER_EXEC} make install
else
    ${DOCKER_EXEC} ./configure
    ${DOCKER_EXEC} make dist
    ${DOCKER_EXEC} /bin/sh -c 'cp -fv pbspro-*.tar.gz /root/rpmbuild/SOURCES/'
    ${DOCKER_EXEC} rpmbuild -bb pbspro.spec
    ${DOCKER_EXEC} /bin/sh -c 'zypper --no-gpg-checks -n install /root/rpmbuild/RPMS/x86_64/pbspro-server-*.x86_64.rpm'
fi
${DOCKER_EXEC} /etc/init.d/pbs start
${DOCKER_EXEC} zypper -n install python-pip sudo which net-tools man time.x86_64

