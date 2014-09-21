#!/bin/sh -xe

# update system
sudo pkg update
sudo pkg upgrade -y

sudo pkg install -y cmake git

# install newest buildbot using pip
sudo pkg install -y py27-pip
sudo pip install buildbot-slave

SECRET=`cat .i10secret`

buildslave create-slave slave i10login.iti.kit.edu:9989 i10vb-fbsd10 $SECRET
buildslave start slave
