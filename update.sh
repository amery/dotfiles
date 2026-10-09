#!/bin/sh

set -eu

cd "$(dirname "$0")"

branch="$(git symbolic-ref -q --short HEAD)" || exit

remote=$(git config --get "branch.$branch.remote")
rbranch=$(git config --get "branch.$branch.merge" | sed -e 's|^refs/heads/||')
rurl=$(git config --get "remote.$remote.url")
[ -n "$rbranch" ] || exit

echo "# $PWD ($branch <- $rurl:$rbranch)"

# Unmerged paths left by an earlier run stop this one. The test comes
# before the fetch, or the run after resolving them would find nothing
# new and skip the rebase.
if [ -n "$(git ls-files -u)" ]; then
	echo "unmerged paths remain" >&2
	exit 1
fi

# hash0 is empty when the upstream branch has not been fetched yet.
hash0=$(git rev-parse -q --verify "$remote/$rbranch") || hash0=
git fetch "$remote"
hash1=$(git rev-parse "$remote/$rbranch")
[ "$hash0" != "$hash1" ] || exit 0

git rebase --autostash "$remote/$rbranch"
# The rebase exits 0 when reapplying the autostash conflicts, leaving
# the paths unmerged and the changes kept in the stash.
[ -z "$(git ls-files -u)" ] || exit
git submodule update --init

[ $# -eq 0 ] || exec "$@"
