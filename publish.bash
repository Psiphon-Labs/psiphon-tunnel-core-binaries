#!/usr/bin/env bash

set -e -u -x

# binary-name should not contains spaces.
# paths should be absolute.
# local-temp-clone-path contents will be deleted.
if [ "$#" -ne 4 ]; then
    echo "required arguments: binary-name local-binary-path local-buildinfo-path local-temp-clone-path"
    exit 1
fi

binary_name=$1
local_binary_path=$2
local_buildinfo_path=$3
local_temp_clone_path=$4

repo=https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries.git

# Always start from a clean psiphon-tunnel-core-binaries clone. Limit history depth
# to limit download size and required disk space.
rm -rf $local_temp_clone_path
git clone --depth 1 $repo $local_temp_clone_path

# By convention, psiphon-tunnel-core buildinfo files record the rev on the 3rd line.
buildrev=$(cat "${local_buildinfo_path}" | head -n 3 | tail -n 1)
commit_message="${binary_name} $buildrev"

cd "${local_temp_clone_path}"

# With cloned history depth of 1, this only checks if the most recent build was the same rev.
if [ $(git log | grep "$commit_message" | wc -l) == 1 ]; then
    echo "existing binary commit found, skipping publication"
    exit 0
fi

mkdir -p "./${binary_name}"

cp "${local_binary_path}" "./${binary_name}"
git add "./${binary_name}"

# Use --allow-empty: if the binary happens to be identical to the previous commit, still
# push the new rev.
git commit --allow-empty --message="$commit_message"
git push origin master

rm -rf "${local_temp_clone_path}"

echo "publish finished"
