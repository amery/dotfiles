#!/bin/sh

set -eu
cd "$(dirname "$0")"
git submodule update --init
./sync.sh

# print the primary-key fingerprint of a key already in the keyring
key_fpr() {
	gpg --batch --with-colons --fingerprint "$1" |
		awk -F: '/^fpr:/{ print $10; exit }'
}

# Import our own public keys and mark them ultimately trusted.
# sync.sh only symlinks the .asc into ~/.gnupg; GnuPG never imports
# loose key files on its own, so without this the keyring stays empty
# and git-set-user has no key to match or sign with.
if command -v gpg > /dev/null 2>&1; then
	for asc in files/.gnupg/*.asc; do
		[ -e "$asc" ] || continue
		gpg --batch --import "$asc"
		fpr="$(key_fpr "$(basename "$asc" .asc)")"
		if [ -n "$fpr" ]; then
			printf '%s:6:\n' "$fpr" |
				gpg --batch --import-ownertrust
		fi
	done
fi

git reset --hard
