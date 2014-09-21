#!/bin/bash -xe

# update system
sudo bash -c 'echo "deb http://old-releases.ubuntu.com/ubuntu hardy-backports main restricted universe multiverse" >> /etc/apt/sources.list'

sudo apt-get update
sudo apt-get upgrade -y

# install basic build packages
sudo apt-get install -y build-essential cmake
sudo apt-get install -y g++-3.3 g++-3.4 g++-4.1

# install newer git
GITVER=2.1.1
sudo apt-get build-dep -y git-core
wget --no-check-certificate http://www.kernel.org/pub/software/scm/git/git-$GITVER.tar.gz
tar xzf git-$GITVER.tar.gz
cd git-$GITVER/
./configure --prefix=/usr/
make
sudo make install
cd ..
rm -rf git-$GITVER

# install newest buildbot using easy_install
sudo apt-get install -y python-setuptools python-dev
sudo easy_install buildbot-slave

SECRET=`cat .i10secret`

buildslave create-slave slave i10login.iti.kit.edu:9989 i10vb-ubu8-32 "$SECRET"
buildslave start slave
