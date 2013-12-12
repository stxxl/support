#!/bin/bash
############################################################################
#  upload.sh
#
#  Bash script to update doxygen documentation of branches and upload
#  the compiled website to sourceforge.
#
#  Part of the STXXL. See http://stxxl.sourceforge.net
#
#  Copyright (C) 2013 Timo Bingmann <tb@panthema.net>
#
#  Distributed under the Boost Software License, Version 1.0.
#  (See accompanying file LICENSE_1_0.txt or copy at
#  http://www.boost.org/LICENSE_1_0.txt)
############################################################################

# function to run program and check return code
run() {
    echo -- $@
    "$@"
    if [ $? != 0 ]; then
        echo "Failed with return code $?"
        exit
    fi
}

# check doxygen version
if [ `doxygen --version` != "1.8.5" ]; then
    echo "Wrong doxygen version installed. We require version 1.8.5!"
    exit
fi

# check that we are at the base of the webpage gitrepo
if [ ! -e "index.html" ]; then
    echo "Run this script at the base directory of the webpage!"
    exit
fi

# path to temporary stxxl repo to generate doxygen (is updated if it exists)
TMPREPO=/tmp/stxxl-doxy-update

# reset webpage gitrepo (cleans everything except tags/master)
run git fetch --all
run git reset --hard origin/master
run git clean -d -f

# update doxygen from a branch
update_doxy() {
    BRANCH=$1

    # get the git hash from previous commit
    PREVHASH=`cat tags/$BRANCH/githash.txt`

    ### Get a clean stxxl repository

    # destination path of documentation
    DOCOUT=$PWD/tags/$BRANCH

    if [ ! -d "$TMPREPO" ]; then
        run git clone ssh://git@github.com/stxxl/stxxl.git $TMPREPO
    fi

    pushd $TMPREPO

    run git fetch --all
    run git reset --hard origin/$BRANCH
    run git clean -d -f -x

    # failsafe check
    [ -e "include/stxxl.h" ] || exit

    # check if the branch has changed
    if [ "`git rev-parse HEAD`" == "$PREVHASH" ]; then
        echo "Branch $BRANCH remains unchanged."
        popd
        return
    fi

    ### Generate clean doxygen documentation

    # move config.h.in to config.h
    mv include/stxxl/bits/config.h.in include/stxxl/bits/config.h

    run doxygen

    DOXYPATH=doxygen-html
    if [ -e doc/doxy/html/index.html ]; then
        DOXYPATH=doc/doxy/html
    fi

    ### Insert git branch and SHA in footer on each page.

    GITDESC=`git describe --tags`
    GITHASH=`git rev-parse HEAD`

    GATRACK="<script type=\"text/javascript\">\\
var _paq = _paq || [];\
  _paq.push(['trackPageView']);\
  _paq.push(['enableLinkTracking']);\
  (function() {\
    var u='http://panthema.net/wik-331/';\
    _paq.push(['setTrackerUrl', u+'js/']);\
    _paq.push(['setSiteId', '1']);\
    var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0]; g.type='text/javascript';\
    g.defer=true; g.async=true; g.src=u+'js/'; s.parentNode.insertBefore(g,s);\
  })();\\
</script>\\
<noscript><img src=\"http://panthema.net/wik-331/js/?idsite=1\&amp;rec=1\" style=\"border:0\" alt=\"\" /></noscript>"

    sed -i "s@<li class=\"footer\">Generated@<li class=\"footer\"><a href=\"http://github.com/stxxl/stxxl/commit/$GITHASH\">STXXL $GITDESC</a>$GATRACK - Generated@" $DOXYPATH/*.html
    if [ $? != 0 ]; then
        echo "Sed failed with return code $?"
        exit
    fi

    # save current git hash for future comparison
    echo $GITHASH > $DOXYPATH/githash.txt

    # copy back
    run rsync -a --delete $TMPREPO/$DOXYPATH/ $DOCOUT/

    # back to webpage directory
    popd
}

update_doxy master
#update_doxy 1.3

# double check
[ -e "index.html" ] || exit

# copy to sourceforge
run rsync -az --delete-after \
    --exclude /.git \
    --exclude /upload.sh \
    $PWD/ \
    bingmann@web.sourceforge.net:/home/project-web/stxxl/htdocs/
