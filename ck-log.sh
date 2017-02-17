#!/bin/bash -x

set -e

pwd=$PWD

new() {
    rm -rvf $pwd/new-log/
    cd $pwd/stxxl
    for f in `find -xtype f | grep -v .git`; do
        mkdir -p $pwd/new-log/`dirname $f`
        git log --name-status --follow $f > $pwd/new-log/$f
    done
}

orig() {
    cd $pwd/stxxl
    L=`find -xtype f | grep -v .git`

    rm -rvf $pwd/old-log/
    cd ../stxxl-orig
    for f in $L; do
        mkdir -p $pwd/old-log/`dirname $f`
        git log --name-status --follow $f > $pwd/old-log/$f
    done
}

new
orig
