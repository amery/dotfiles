#!/bin/sh
#
# SC2166: -o and -a are well defined here, and read better than
# splitting a test into two commands joined by ||. The operands are
# always "$SSHDIR"-prefixed paths, never operator-like.
# shellcheck disable=SC2166

set -eu

SSHDIR="$HOME/.ssh"

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
			name="$(echo "$l" | cut -d' ' -f3)"
			if [ -n "$name" ]; then
				echo "$l" > "$SSHDIR/$name.pub"
			fi
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
