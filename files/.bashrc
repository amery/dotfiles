# ~/.bashrc: executed by bash(1) for non-login shells.

export LANG="en_GB.UTF-8"
export LC_ALL="$LANG"

# standardise $TERM
case "${TERM:-}" in
""|"unknown") export TERM=dumb ;;
xterm-ghostty) export TERM=xterm-256color ;;
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

# GPG
#
# wants_gpg_agent succeeds only on a machine that owns its gpg-agent, where a
# local agent should be launched. Two independent scenarios borrow an agent
# instead and must not start their own:
#   - SSH remote: the laptop's agent is forwarded over the tunnel.
#   - container:  the host's gnupg runtime dir is bind-mounted in.
wants_gpg_agent() {
	local sock_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/gnupg"

	# remote: forwarded agent
	case "${SSH_CONNECTION:-}" in
	?*) return 1 ;;
	esac

	# container: bind-mounted agent
	! grep -qsF " $sock_dir " /proc/mounts || return 1

	return 0
}

# gpg_agent_state reports what sits behind the agent socket: live, stale,
# absent, or occupied. Only `occupied` needs a clock -- a socket something
# listens on but nobody answers on, as a Dev Containers relay leaves behind
# when it outlives the agent it forwards to. gpg-connect-agent imposes no
# connect timeout of its own, so launching against one of those spawns an
# agent that cannot bind and then waits out a fixed countdown, paid once per
# shell and serialised on the spawn lock. A missing `timeout` falls through
# to `stale`, which is the launch-anyway behaviour this replaces.
gpg_agent_state() {
	local sock rc out

	sock="$(gpgconf --list-dirs agent-socket)"
	if [ ! -S "$sock" ]; then
		echo absent
		return 0
	fi

	# --no-autostart exits 0 whether or not it reached an agent, so the
	# `OK` on stdout is the only liveness signal. `timeout` supplies the
	# connect timeout gpg-connect-agent has none of.
	rc=0
	out="$(timeout 2 gpg-connect-agent --no-autostart NOP /bye \
		2> /dev/null)" || rc=$?

	case "$rc" in
	124)
		echo occupied
		return 0
		;;
	esac

	case "$out" in
	OK*) echo live ;;
	*) echo stale ;;
	esac
}

if type -p gpgconf > /dev/null; then
	export GPG_TTY=$(tty)
	: "${GNUPGHOME:=$HOME/.gnupg}"
	export GNUPGHOME
	# gpg refuses a homedir that group/other can access
	[ ! -d "$GNUPGHOME" ] || chmod go-rwx "$GNUPGHOME"
	if wants_gpg_agent; then
		case "$(gpg_agent_state)" in
		live) ;;
		occupied)
			echo "gpg-agent socket occupied but silent;" \
				"not launching (ss -xlp | grep S.gpg-agent)" >&2
			;;
		*) gpgconf --launch gpg-agent ;;
		esac
	fi
fi

unset wants_gpg_agent gpg_agent_state

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

# run make/go offline against the module cache (no proxy, no sumdb, no
# toolchain download): go-cached make ...
alias go-cached='env GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local'

# refresh stale VSCode / Remote-Containers env from the live window that
# owns this pane.
alias vsr='eval "$(vscode-refresh-env)"'

[ "$(type -t ll)" != alias ] || unalias ll
ll() { ls -avhlF "$@" | less; }

# vi mode
set -o vi

# local settings
may_source .bash/local.in
may_source /etc/bash_completion

unset may_source
