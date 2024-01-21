#!/bin/sh

SSHDIR="$HOME/.ssh"

keys=
for x in $SSHDIR/*.pub; do
	if [ -s "$x" ]; then
		keys="$keys $x"
	else
		rm "$x"
	fi
done

ak="$SSHDIR/authorized_keys"
if [ -s "$ak" ]; then
	while read l; do
		found=
		for k in $keys; do
			read l2 < $k || true
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
	done < $ak > $ak~
else
	touch $ak
	for x in amery@geeks.cl \
		amery@builder.geeks.cl \
		amery@shell.easy-cloud.net; do
		x="$SSHDIR/$x.pub"
		[ -s "$x" ] || continue
		cat "$x"
	done > $ak~
fi
if ! cmp $ak $ak~; then
	diff -u $ak $ak~ || true
	mv $ak~ $ak
fi
