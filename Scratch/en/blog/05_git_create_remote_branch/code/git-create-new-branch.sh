#!/usr/bin/env zsh

if (($#<1)); then
    print -- "usage: $0:t branch_name" >&2
    exit 1
fi

branch=$1
git br ${branch}
git co ${branch}
git config branch.${branch}.remote origin
git config branch.${branch}.merge refs/heads/${branch}
    