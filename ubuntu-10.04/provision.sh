#!/bin/bash -xe

# update system
sudo apt-get update
sudo apt-get dist-upgrade -y

# install basic build packages
sudo apt-get install -y build-essential git-core cmake libboost-all-dev
sudo apt-get install -y g++-4.1 g++-4.3 g++-4.4

# install newest buildbot using pip
sudo apt-get install -y python-pip
sudo pip install buildbot-slave

SECRET=`cat .i10secret`

buildslave create-slave slave i10login.iti.kit.edu:9989 i10vb-ubu10 "$SECRET"
buildslave start slave
