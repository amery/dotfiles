#!/bin/sh
#
# SC2166: -o and -a are well defined here, and read better than
# splitting a test into two commands joined by ||. The operands are
# always "$SSHDIR"-prefixed paths, never operator-like.
# shellcheck disable=SC2166

set -eu

# Everything created here (authorized_keys, its temp, extracted .pub
# captures) must stay private; sshd rejects a group-writable
# authorized_keys under StrictModes.
umask 077

SSHDIR="$HOME/.ssh"

# keyname derives a filesystem-safe base name for an unrecognised key
# line so the capture always has a writable filename. It scans past any
# options prefix to the key-type token and prefers the trailing comment;
# with no comment it falls back to the type and a checksum of the line.
# The result is reduced to a plain name -- no separators, no hidden or
# relative form -- and length-capped. Call it in a command substitution:
# the set -f / set -- here must not disturb the caller's allowlist in $@.
keyname() {
	line=$1
	set -f
	# shellcheck disable=SC2086  # deliberate word-split of the key line
	set -- $line
	while [ $# -gt 0 ]; do
		case "$1" in
		ssh-*|ecdsa-*|sk-*) break ;;
		esac
		shift
	done
	kt=${1:-key}
	if [ $# -gt 2 ]; then
		shift 2
		name=$*
	else
		name="$kt-$(printf '%s' "$line" | cksum | cut -d' ' -f1)"
	fi
	name=$(printf '%s' "$name" | tr -c 'A-Za-z0-9._@-' '_' | cut -c1-64)
	case "$name" in
	''|.*|-*) name="key_$name" ;;
	esac
	printf '%s\n' "$name"
}

set --
for x in "$SSHDIR"/*.pub; do
	[ -e "$x" -o -L "$x" ] || continue
	if [ -s "$x" ]; then
		set -- "$@" "$x"
	else
		rm "$x"
	fi
done

ak="$SSHDIR/authorized_keys"
trap 'rm -f "$ak~"' EXIT

if [ -s "$ak" ]; then
	while read -r l; do
		found=
		for k; do
			read -r l2 < "$k" || true
			if [ "$l" = "$l2" ]; then
				found=yes
				echo "$l"
				break
			fi
		done

		if [ -z "$found" ]; then
			echo "$l" > "$SSHDIR/$(keyname "$l").pub"
		fi
	done < "$ak" > "$ak~"
else
	touch "$ak"
	for x in amery@geeks.cl \
		amery@builder.geeks.cl \
		amery@shell.easy-cloud.net; do
		x="$SSHDIR/$x.pub"
		[ -s "$x" ] || continue
		cat "$x"
	done > "$ak~"
fi
if ! diff -u "$ak" "$ak~"; then
	mv "$ak~" "$ak"
fi

# Guarantee the final mode even when nothing changed: umask only sets it
# on files this run creates, so a pre-existing group-writable file that
# needs no rewrite would otherwise keep its mode and stay rejected.
chmod 600 "$ak"
