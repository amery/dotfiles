#!/bin/sh

set -u

cd "$(dirname "$0")"

branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
[ -n "$branch" ] || exit

remote=$(git config --get "branch.$branch.remote")
rbranch=$(git config --get "branch.$branch.merge" | sed -e 's|^refs/heads/||')
rurl=$(git config --get "remote.$remote.url")
[ -n "$remote" -a -n "$rbranch" -a -n "$rurl" ] || exit

echo "# $PWD ($branch <- $rurl:$rbranch)"

hash0=$(git rev-parse "$remote/$rbranch")
git fetch "$remote"
hash1=$(git rev-parse "$remote/$rbranch")
[ -n "$hash0" -a -n "$hash1" -a "$hash0" != "$hash1" ] || exit

if [ "$(git ls-files -md)" ]; then
	stashed=true
	git stash -q
else
	stashed=false
fi

git rebase "$remote/$rbranch"
git submodule update --init

if $stashed; then
	git stash pop -q
fi

[ $# -eq 0 ] || exec "$@"
