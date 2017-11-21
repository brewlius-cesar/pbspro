#!/bin/bash -xe
BUILDPKGS='build-essential dpkg-dev autoconf libtool rpm alien libssl-dev libxt-dev libpq-dev libexpat1-dev libedit-dev libncurses5-dev libical-dev libhwloc-dev pkg-config tcl-dev tk-dev python-dev swig'
DEPPKGS='expat postgresql'
TESTPKGS='python-pip sudo man-db'
${DOCKER_EXEC} apt-get -qq update
${DOCKER_EXEC} apt-get install -y $BUILDPKGS $DEPPKGS $TESTPKGS
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
    ${DOCKER_EXEC} /bin/sh -c 'mkdir -p /root/rpmbuild/SOURCES/; cp -fv pbspro-*.tar.gz /root/rpmbuild/SOURCES/'
    ${DOCKER_EXEC} /bin/sh -c 'mkdir /etc/rpm/; cp -v .travis/debian.macros.dist /etc/rpm/macros.dist'
    ${DOCKER_EXEC} rpmbuild -bb --nodeps pbspro.spec
    ${DOCKER_EXEC} /bin/sh -c 'alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/pbspro-server-*.x86_64.rpm'
    ${DOCKER_EXEC} /bin/sh -c 'dpkg -i pbspro-server_*_amd64.deb'
fi
${DOCKER_EXEC} /etc/init.d/pbs start

