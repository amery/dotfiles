#!/bin/sh

info() { echo "$$: $*"; }
err() { echo "E: $$: $*" >&2; }

set -u

if [ "x-d" = "x${1:-}" ]; then
	BASE="$2"
	shift 2
else
	BASE=.
fi

FILES="$(readlink -f "$BASE")"
for x; do

	# clean
	#
	case "$x" in
	"$BASE")   continue ;;
	"$BASE"/*) x="${x#$BASE/}" ;;
	./*)       x="${x#./}" ;;
	esac

	# find target (d1)
	#
	if [ -L "$FILES/$x" ]; then
		d0="$(readlink "$FILES/$x")"
		d1="$(readlink -f "$FILES/$x")"

		[ "$d1" = "${d1#$FILES/}" ] || d1="$d0"
	elif [ ! -d "$FILES/$x" ]; then
		d1="$FILES/$x"
	else
		continue
	fi

	# link dir
	#
	d="${x%/*}"
	if [ "$d" = "$x" ]; then
		d=
	elif [ ! -d "$HOME/$d/" ]; then
		info "$d: creating dir"
		mkdir -p "$HOME/$d/"
	fi

	# link
	#
	if [ -L "$HOME/$x" ]; then
		# preexisting link ($d1)
		d0="$(readlink "$HOME/$x")"

		[ "$d0" != "$d1" ] || continue

		err "$x: relinking, was [$d0]"
	elif [ ! -e "$HOME/$x" ]; then
		# new
		info "$x: linking"
	elif [ -d "$HOME/$x" ]; then
		# preexisting dir

		err "$x: importing directory and linking [$d1]"
		if ! rmdir "$HOME/$x" 2> /dev/null; then
			rm "$FILES/$x"
			mv "$HOME/$x" "$FILES/$x"
		fi
	else
		# preexisting file
		info "$x: importing changes and linking [$d1]"
		rm "$FILES/$x"
		cp -a "$HOME/$x" "$FILES/$x"
	fi

	ln -snf "$d1" "$HOME/$x"
done
