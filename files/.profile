# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.

# redirect bash to .bashrc (for `screen`)
if [ -n "$BASH_VERSION" ]; then
	if [ -s "$HOME/.bashrc" ]; then
		. "$HOME/.bashrc"
	fi
fi

# set PATH so it includes user's private bin if it exists
to_path() {
	local d1="$1" d2

	[ -d "$d1" ] || return 1
	d2="$(cd "$d1" 2>/dev/null && pwd -P)"
	[ -d "$d2" ] || return 1

	# PATH
	case ":$PATH:" in
	*":$d2:"*) : ;;
	*)
		export PATH="$d2:$PATH"
		;;
	esac
}

to_path "$HOME/bin"

unset to_path
