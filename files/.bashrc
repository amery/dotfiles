# ~/.bashrc: executed by bash(1) for non-login shells.

export LANG="en_GB.UTF-8"

# standarise $TERM
case "${TERM:-}" in
""|"unknown") TERM=dumb ;;
esac

# PATH
#
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

to_path "~/.local/share/pnpm" "" PNPM_HOME
to_path "~/.local/share/npm" "bin" NPM_HOME
to_path "~/.local/bin"
to_path "~/bin"

unset to_path

# If not running interactively, don't do anything
[ -n "$PS1" ] || return

# GPG
#
x="$HOME/.gpg-agent-info"
if ! type -p gpg-agent > /dev/null; then
	rm -f "$x"
elif test -s "$x" &&
	kill -0 $(cut -d: -f2 "$x" 2> /dev/null ) 2> /dev/null; then

	. "$x"
else
	eval $(gpg-agent --daemon --log-file "$HOME/.gpg-agent.log" \
		--write-env-file "$x" 2> /dev/null)

fi
if [ -s "$x" ]; then
	export GPG_TTY=$(tty)
	eval export $(cut -d= -f1 "$x")
fi
unset x

# ssh wrapper
#
if [ -s "$HOME/bin/ssh" ]; then
	SSH="$HOME/bin/ssh"
else
	SSH=ssh
fi

for x in GIT_SSH; do
	eval export "$x=$SSH"
done

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

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# support resize, please
shopt -s checkwinsize

# get a nicer $PS1
if [ -s $HOME/.bash/prompt.in ]; then
	. $HOME/.bash/prompt.in
fi

# aliases
#
alias ls='ls --color=auto'
alias l='ls -avhlF'
alias gdb='gdb -quiet'
alias vi='vi "+set encoding=utf-8"'

[ "$(type -t ll)" != alias ] || unalias ll
function ll() { ls -avhlF $* | less; }

# vi mode
set -o vi

# local settings
for x in .bash/local.in /etc/bash_completion; do
	expr "$x" : / > /dev/null || x="$HOME/$x"
	 
	if [ -s "$x" ]; then
		. "$x"
	fi
done
