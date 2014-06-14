#!/bin/bash -x

set -e

GITREPO1=git@github.com:bingmann/stxxl-svn-import-archive.git
[ -e ~/stxxl-svn-import-archive.git ] && GITREPO1=~/stxxl-svn-import-archive.git

GITREPO2=git@github.com:stxxl/stxxl.git
[ -e ~/stxxl.git ] && GITREPO2=~/stxxl.git

rm -rf stxxl-graft
git clone $GITREPO1 stxxl-graft

cd stxxl-graft

for branch in `git branch -a | grep remotes | grep -v master`; do
    git branch --track ${branch#remotes/origin/} $branch
done

# fetch official master branch as master-new
git fetch $GITREPO2 master
git branch master-new FETCH_HEAD

# generate graft points mapping master -> master-new for these branches
BRANCHES=kernelaio posixaio unordered_map
#BRANCHES=parallel_pipelining parallel_pipelining_integration

perl ../graft-matcher.pl $BRANCHES | tee .git/info/grafts

# make grafts permanent
git filter-branch --tag-name-filter cat -- --all

git push git@github.com:bingmann/stxxl2.git --force master-new $BRANCHES
