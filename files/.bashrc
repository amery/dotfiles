# ~/.bashrc: executed by bash(1) for non-login shells.

export LANG="en_GB.UTF-8"

# standardise $TERM
case "${TERM:-}" in
""|"unknown") export TERM=dumb ;;
esac

# to_path <home> [bin] [VAR]
#   add [bin] (default: <home>) to PATH.
#   export <home> as $VAR if given.
to_path() {
	local d1="$1" d2="${2:-}" d3 n="${3:-}" base_dir

	# HOME
	case "$d1" in
	"~"|"")    d1="$HOME" ;;
	"~"/*)  d1="$HOME/${d1#\~/}" ;;
	esac

	[ -e "$d1" ] || return 1

	if [ -d "$d1" ]; then
		base_dir="$d1"
	else
		case "$d1" in
		*/*) base_dir="${d1%/*}" ;;
		*)   base_dir="." ;;
		esac
	fi

	# bin dir
	case "$d2" in
	"~")      d2="$HOME" ;;
	"~"/*)    d2="$HOME/${d2#\~/}" ;;
	/*)       ;; # Absolute
	./*|../*) ;; # Relative to CWD
	"")       d2="$d1" ;; # Use d1 if d2 is empty
	*)        d2="$base_dir/$d2" ;;
	esac

	[ -d "$d2/" ] || return 1

	# normalize
	d3="$(cd "$d2" 2>/dev/null && pwd -P)"
	[ -d "$d3" ] || return 1

	# PATH
	case ":$PATH:" in
	*":$d3:"*) : ;;
	*)
		export PATH="$d3:$PATH"
		;;
	esac

	if [ -n "$n" ]; then
		eval "$n=\"$d1\""
		export "$n"
	fi
}

# pnpm
to_path "~/.local/share/pnpm" "" PNPM_HOME
# npm
if to_path "~/.local/share/npm" "bin" NPM_CONFIG_PREFIX; then
	grep -q "^prefix=$NPM_CONFIG_PREFIX$" ~/.npmrc 2>/dev/null ||
		npm config set prefix "$NPM_CONFIG_PREFIX"
fi
# python
to_path "~/.local/share/python/main" "bin" PYTHON_VENV
# misc
to_path "~/.local/bin"
to_path "~/bin"

unset to_path

# If not running interactively, don't do anything
[ -n "$PS1" ] || return

# python aliases
if [ -n "${PYTHON_VENV:-}" ]; then
	alias venv=". $PYTHON_VENV/bin/activate"
	alias unvenv="deactivate"
fi

# ssh wrapper
#
if [ -x "$HOME/bin/ssh" ]; then
	SSH="$HOME/bin/ssh"
else
	SSH=ssh
fi

export GIT_SSH="$SSH"

# debian/ubuntu development
#
export DEBFULLNAME="Alejandro Mery"
export DEBEMAIL="amery@geeks.cl"

# other apps chosen by env
#
export BROWSER=links
export EDITOR=vim

# better utf-8 support
export LESSCHARSET=utf-8

# history
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# support resize
shopt -s checkwinsize

# source file if it exists and is non-empty
may_source() {
	local f="$1"

	case "$f" in
	"~"/*) f="$HOME/${f#\~/}" ;;
	/*)    ;;
	*)     f="$HOME/$f" ;;
	esac

	[ -s "$f" ] || return 0
	. "$f"
}

# get a nicer $PS1
may_source .bash/prompt.in

# aliases
#
alias ls='ls --color=auto'
alias l='ls -avhlF'
alias gdb='gdb -quiet'
alias vi='vi "+set encoding=utf-8"'

[ "$(type -t ll)" != alias ] || unalias ll
ll() { ls -avhlF "$@" | less; }

# vi mode
set -o vi

# local settings
may_source .bash/local.in
may_source /etc/bash_completion

unset may_source
