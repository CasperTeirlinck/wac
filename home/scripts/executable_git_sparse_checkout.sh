#!/bin/bash
# Usage: git_sparse_checkout.sh <url> <subdir>
# with <subdir> the path in the repositry to the sub-directory to clone.

if [[ $# -ne 2 ]] ; then
    echo 'Please provide <url> and <subdir>'
    exit 0
fi

url=$1
subdir_path=$2
subdir_name="$(basename -- $subdir_path)"

git clone --no-checkout "$url" "$subdir_name"
cd "$subdir_name"
git sparse-checkout set "$subdir_path"
git checkout

# temp workaround for fixing p10k git status 
# https://github.com/romkatv/gitstatus/issues/107
# https://github.com/romkatv/gitstatus/issues/203
git config --local core.repositoryformatversion 0 #! no sure about the impact of this
git config --local bash.showDirtyState false