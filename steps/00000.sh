#git init $1
#git svn init --stdlayout --prefix svn/ https://stxxl.svn.sourceforge.net/svnroot/stxxl .

git config svn.findcopiesharder 1
git config svn.authorsfile .git/authors

# up to Feb 2008
cat - > .git/authors << EOF
anbe = Andreas Beckmann <beckmann@mpi-inf.mpg.de>
dementiev = Roman Dementiev <dementiev@ira.uka.de>
singler = Johannes Singler <singler@ira.uka.de>
johannessingler = Johannes Singler <singler@ira.uka.de>
marwes = Markus Westphal <marwes@users.sourceforge.net>
EOF

git config --unset-all svn-remote.svn.fetch || true
git config --add svn-remote.svn.fetch trunk:refs/remotes/svn/trunk
git config --add svn-remote.svn.branches 'branches/*:refs/remotes/svn/*'
git config --add svn-remote.svn.branches 'branches/anbe/*:refs/remotes/svn/branches-anbe/*'
git config --add svn-remote.svn.tags tags/*:refs/remotes/svn/tags/*
