#!/bin/sh
# inspired in parts by http://justatheory.com/computers/vcs/

# revert the last commit on a branch head
undo_branch_head_commit()
{
	git checkout $1
	git reset --hard HEAD^
}

# revert the last commit on a branch head if it is an empty commit
undo_empty_branch_head_commit()
{
	if [ "$(git rev-parse "${1}:")" = "$(git rev-parse "${1}^:")" ]; then
		undo_branch_head_commit $1
	fi
}

# reparent <commit> <new parent>...
# replaces the old parents
reparent()
{
	local g p
	g=$(git rev-parse $1^{commit})
	shift
	for p in "$@"
	do
		g="$g $(git rev-parse $p^{commit})"
	done
	echo "$g" >> .git/info/grafts
}

# add_parent <commit> <new parent>...
# keeps the old parents
add_parent()
{
	local c
	c="$1"
	shift
	reparent $(git rev-list -n 1 --parents $c) "$@"
}

# prepend_parent <commit> <new parent>...
# keeps the old parents
prepend_parent()
{
	local c
	c="$1"
	shift
	local r p
	r=$(git rev-list -n 1 --parents $c | awk '{ print $1 }')
	p=$(git rev-list -n 1 --parents $c | awk '{ $1 = ""; print }')
	reparent $r "$@" $p
}

# remote_branch_to_local_branch <remote branch> [<new local branch name>]
remote_branch_to_local_branch()
{
	git branch "${2:-$1}" "${1}"
	git branch -D -r "$1"
}

# inspired by
# http://www.sonatype.com/people/2011/04/goodbye-svn-hello-git/

# find_sametree_ancestor <old tag or branch name> [<parent branch name>]
find_sametree_ancestor()
{
	local tag_ref trunk
	tag_ref="$1"
	trunk="$2"

	local tree parent_ref parent merge target_ref
    tree=$( git rev-parse "$tag_ref": )

    # find the oldest ancestor for which the tree is the same
    parent_ref="$tag_ref";
    while [ "$( git rev-parse --quiet --verify "$parent_ref"^: )" = "$tree" ]; do
        parent_ref="$parent_ref"^
    done
    parent=$( git rev-parse "$parent_ref" );

    # if this ancestor is in trunk then we can just tag it
    # otherwise the tag has diverged from trunk and it's actually more like a
    # branch than a tag
    merge=$( git merge-base "$trunk" $parent );
    if [ "$merge" = "$parent" ]; then
        target_ref=$parent
    else
        echo "tag '$tag_ref' has diverged from '$trunk'" >&2
        target_ref="$tag_ref"
    fi

    echo "$target_ref"
}

move_tag()
{
	local tag tag_ref target_ref
	tag="$1"
	tag_ref="$2"
	target_ref="$3"

    # create an annotated tag based on the last commit in the tag, and delete the "branchy" ref for the tag
    git show -s --pretty='format:%s%n%n%b' "$tag_ref" | \
    env GIT_COMMITTER_NAME="$(  git show -s --pretty='format:%an' "$tag_ref" )" \
        GIT_COMMITTER_EMAIL="$( git show -s --pretty='format:%ae' "$tag_ref" )" \
        GIT_COMMITTER_DATE="$(  git show -s --pretty='format:%ad' "$tag_ref" )" \
        git tag -a -f -F - "$tag" "$target_ref"
}

# create annotated tag using committer, time, and message from branch head commit
# place tag on the oldest commit that has the same tree-ish as the branch head
# useful for converting git svn 'tag' branches to real tags
# branch_to_tag <old branch name> <new tag name> [<parent branch name>]
branch_to_tag()
{
	local tag_ref tag trunk
	tag_ref="$1"
	tag="$2"
	trunk="$3"

	local target_ref
	target_ref="$(find_sametree_ancestor "$tag_ref" "$trunk")"

	move_tag "$tag" "$tag_ref" "$target_ref"

    git branch -D "$tag_ref"
}

# svntag2gittag <old branch name> <new tag name> [<parent branch name>]
svntag2gittag()
{
	branch_to_tag "$@"
}

# convert a tag to a branch, tag annotation gets lost
# tag_to_branch <tag> [<branch>]
tag_to_branch()
{
	local tag branch
	tag="$1"
	branch="${2:-$1}"

	git branch "$branch" "$tag"
	git tag -d "$tag"
}

# delete_tag_if_tree_matches <tag> <other>
delete_tag_if_tree_matches()
{
	local tree1 tree2
	tree1=$( git rev-parse "$1": )
	tree2=$( git rev-parse "$2": )
	if [ "$tree1" = "$tree2" ]
	then
		git tag -d "$1"
	fi
}

# tag everything with its svn revision
tag_svn_revisions()
{
    local c svnid
    for c in $(git rev-list --all --date-order --timestamp | sort -n | awk '{print $2}')
    do
	svnid=$(git show -s $c | grep git-svn-id | tail -n 1 | sed -r 's/.*@([0-9]+) .*/\1/')
	#echo "$c $svnid"
	test -z "$svnid" || git tag r${svnid} $c || git tag r${svnid}a $c || git tag r${svnid}b $c || git tag r${svnid}c $c
    done
}

untag_svn_revisions()
{
    local t
    for t in $(git tag | grep -E '^r[0-9]+$')
    do
	git tag -d $t
    done
}

tag_cvs_revisions()
{
	local c i
	i=0
	for c in $(awk '{ print $3 }' .git/cvs-revisions | uniq)
	do
		i="$(($i + 1))"
		git tag "CVSr$i" "$c"
	done
}

untag_cvs_revisions()
{
	local t
	for t in $(git tag | grep -E '^CVSr[0-9]+$')
	do
		git tag -d $t
	done
}

rewrite_history()
{
	#git rev-list --all --parents > revlist.old
	tmpd=$(mktemp -d gfbXXXXXXXX)
	git filter-branch -d "$tmpd/gfb" --tag-name-filter cat -- --all
	rm -rf "$tmpd"
	rm -f .git/info/grafts
	git for-each-ref --format="%(refname)" refs/original/ | xargs -r -n 1 git update-ref -d
	#git rev-list --all --parents > revlist.new
}
