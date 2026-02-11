#!/bin/sh

set -e

die() {
	echo "$*" >&2
	exit 1
}

N="$(basename "$0")"
case "$N" in
sshfs_*)
	M=sshfs
	N="${N#sshfs_}"
	case "$N" in
	inmep)
		R=amery@inmep.geeks.cl:projects/
		;;
	builder)
		R=amery@geeks.cl:projects/
		;;
	*)
		R=$N:
		;;
	esac
	;;
flickr)
	M="${N}fs"
	;;
*)
	die "$0: invalid name"
	;;
esac

D="/media/$USER/$N"
if [ ! -d "$D/" ]; then
	sudo mkdir -p "$D"
	sudo chown "$USER:$USER" "$D"
fi

case "$M" in
sshfs)
	sshfs_opt="-o reconnect -C"
	if grep -q '^user_allow_other$' /etc/fuse.conf 2> /dev/null; then
		sshfs_opt="$sshfs_opt -o allow_root"
	else
		echo "please enable user_allow_other in /etc/fuse.conf and make it readable" >&2
	fi

	exec "$M" $sshfs_opt "$@" \
		"$R" "$D"
	;;
flickrfs)
	exec "$M" "$D"
	;;
*)
	die "$M: invalid mode"
	;;
esac
