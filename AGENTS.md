# AI Agent Guide

Instructions for AI agents operating on machines
where these dotfiles are deployed.

## Dotfiles Are Symlinks

Files in `$HOME` such as `.bashrc`, `.gitconfig`,
and `.vimrc` are symlinks into this repository
under `files/`.

**Do not copy or overwrite files in `$HOME`.**
Edit the source in the dotfiles checkout instead.
The symlink ensures `$HOME` sees the change
immediately.

The dotfiles repo is typically checked out at
`~/projects/dotfiles`.

`sync.sh` creates the symlinks. When a target
already exists in `$HOME`:

- **Regular file**: imported into `files/`, then
  replaced with a symlink.
- **Non-empty directory**: moved into `files/` and
  replaced with a symlink.
- **Existing symlink**: relinked if it points
  somewhere else.

`sync_ssh.sh` runs automatically after every sync.

To re-sync after changes (the script changes to
its own directory, no `cd` needed):

```sh
~/projects/dotfiles/sync.sh
```

`bootstrap.sh` does the same but also initialises
submodules, imports the shipped GPG public keys,
and runs `git reset --hard` afterward.

## Environment

`.bashrc` sets up `PATH` before the interactive
shell guard. Non-interactive sessions such as
`ssh host command` have access to:

- `~/bin` -- utility scripts from this repo
- `~/.local/bin` -- locally installed binaries
- npm global binaries (via `NPM_CONFIG_PREFIX`)
- pnpm global binaries (via `PNPM_HOME`)
- python virtualenv at `~/.local/share/python/main`
  (via `PYTHON_VENV`), `venv`/`unvenv` aliases in
  interactive shells

`.profile` independently adds `~/bin` to `PATH`
for non-bash login shells (`dash`, `sh`) that do
not source `.bashrc`.

You do not need to manually export `PATH`.

## Workspace Entry Points

Use `x` to find and execute a project's `run.sh`:

```sh
x              # find and run nearest run.sh
x --root       # print workspace root path
x -C /path     # operate from a different dir
x -- cmd args  # run cmd if no run.sh found
```

`x` searches upward through parent directories,
checking `.repo` workspaces first, then git
repositories, looking for an executable `run.sh`
at the root.

## Scripts

Key scripts in `~/bin/`:

| Script           | Purpose                      |
|------------------|------------------------------|
| `x`              | Run a workspace's `run.sh`   |
| `icdiff`         | Side-by-side diff with color |
| `git-icdiff`     | icdiff as git diff driver    |
| `git-set-user`   | Set identity + signingkey    |
| `colorize`       | Syntax-highlight any file    |
| `pcat`           | Filter and colorize pipeline |
| `vcs_update`     | Pull and rebase any VCS repo |
| `mkgit`          | Init repo with remote        |
| `repo-find`      | Find files in repo workspace |
| `repo-grep`      | Grep across repo workspace   |
| `repo-list`      | List git repos recursively   |
| `repo-root`      | Print repo workspace root    |
| `sshloop`        | Reconnecting SSH wrapper     |
| `tmux-reattach`  | Attach or create tmux/screen |
| `tmux-here`      | Per-directory tmux session   |
| `getpem`         | Extract public key from TLS  |

Run `ls ~/bin/` for the full list of scripts.

## Shell Conventions

Follow these when writing or modifying shell
scripts in this repository:

- Start with `#!/bin/sh` and `set -eu`
- Use `||` guards, not `&&`: with `set -e`, a
  trailing `check && action` aborts the script
  when the check fails
- Use `${VAR:-}` for potentially unset variables
- Use `case` over `if/elif` for string matching
- Quote all variable expansions
- Target POSIX `sh`, not Bash
- Scripts should pass `shellcheck`

## Git Commit Style

```text
prefix: short description in lowercase
```

The prefix identifies the area of change:

```text
bashrc: set up PATH before the interactive guard
bin: add icdiff and git-icdiff via submodule
modules: update 3rd-party submodules
ssh: fix storing of old keys on sync
bootstrap: cd to checkout dir
vim: add editorconfig-vim support
```

Do not capitalise the description. Do not end it
with a period.

Commits and tags are GPG-signed: `.gitconfig` sets
`commit.gpgsign` and `tag.gpgsign` to `true` with a
configured `user.signingkey`. A bare `git commit`
will attempt to sign, so a working `gpg` agent must
be available. Use `git commit -s` to add the
`Signed-off-by` trailer as well.

Use `git set-user [<email>]` to point a
repository's identity -- `user.name`,
`user.email` and `user.signingkey` -- at a
matching GnuPG secret key; with no argument it
re-derives them from the configured `user.email`.
When no secret key matches, the address is still
set but `user.signingkey` is removed so commits
are not signed with the wrong key. `git set-user
--list` shows the available identities.

## Sharing the GPG Agent

The private keys live only on the laptop that owns
the `gpg-agent`. Every other environment borrows
that agent rather than holding a copy of the keys,
so signing always happens on the laptop. `.bashrc`
launches a local agent only on the owning machine;
`wants_gpg_agent` bows out in the two borrow
scenarios below. The launch is idempotent, so any
new terminal or tmux pane on the laptop re-arms the
agent once it has died.

`gpg_agent_state` decides whether that launch is
worth making, reporting `live`, `stale`, `absent`
or `occupied`. The first three are cheap to judge,
but `occupied` needs a clock: a socket something
listens on and nobody answers on -- what the Dev
Containers relay leaves behind when it outlives the
agent it forwards to. Launching against one of
those cannot work, and costs a fixed countdown
(8s on gnupg 2.4.7) that every shell pays in turn,
serialised on the spawn lock. So that state warns
instead, naming `ss -xlp | grep S.gpg-agent` to
identify the holder -- `node` for the relay,
`sshd-session` for a forward, `gpg-agent` for a
healthy one. It never unlinks the socket: the
holder may be serving a running container, and
unlinking a live agent socket is the very fault
this guards against.

Two gnupg behaviours the check has to work around.
`gpg-connect-agent --no-autostart` exits 0 whether
or not it reached an agent, so `OK` on stdout is
the only liveness signal; and it imposes no connect
timeout, so a silent socket hangs it indefinitely.

### SSH Remotes

On remote hosts the laptop's `gpg-agent` is
forwarded over SSH, so signing happens on the
laptop while `git` runs on the remote. The private
keys are never copied.

#### One-Time Setup

On the client, forward the laptop's restricted
`extra` socket onto the remote's standard socket
(`~/.ssh/config` for that host):

<!-- markdownlint-disable MD013 -->

```text
RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra
```

<!-- markdownlint-enable MD013 -->

On the remote, let the forward replace an existing
socket file (`/etc/ssh/sshd_config.d/*.conf`, needs
root, then reconnect):

```text
StreamLocalBindUnlink yes
```

Also on the remote, stop systemd from binding the
standard socket: socket activation starts a local
agent on first use, displacing the forward.

```sh
systemctl --user mask gpg-agent.socket gpg-agent.service
```

Import the public keys on the remote. The forwarded
socket carries private keys by keygrip only -- it
has no user IDs -- so `git set-user` cannot match an
address until the matching public key is in the
keyring. `bootstrap.sh` imports the shipped
`files/.gnupg/*.asc` and marks them ultimately
trusted; by hand it is:

```sh
gpg --import ~/.gnupg/*.asc
printf '%s:6:\n' "<fingerprint>" | gpg --import-ownertrust
```

#### Daily Operation

Stop a stray `gpg` from clobbering the tunnel. Any
`gpg` call starts a local agent when none answers,
and that agent binds the standard socket -- unlinking
the forwarded one and leaving a key-less agent in its
place. The shipped `gpg.conf` sets `no-autostart` to
prevent this, so a forward gap makes `gpg` fail
loudly instead of replacing the tunnel. A local agent
is only started explicitly by `.bashrc`, and only on
the owning machine -- never on an SSH remote or inside
a bind-mounted container.

The forward binds when the SSH connection is
established. A multiplexed connection reuses the
existing master, so reconnecting does not re-arm
it; instead, ask the live master to add the
forward, from the laptop:

```sh
ssh -O forward \
  -R /run/user/1000/gnupg/S.gpg-agent:/run/user/1000/gnupg/S.gpg-agent.extra \
  <host>
```

To verify it is live:

- `gpg --list-secret-keys` shows the keys with a `>`
  stub.
- `echo test | gpg --clearsign` succeeds and the
  pinentry prompt appears on the laptop.

### Containers

A container borrows the agent through a bind mount
of the laptop's `/run/user/1000/gnupg` runtime
directory. The directory is mounted, not the socket
file, so an agent restart -- which recreates the
socket inode -- is picked up without restarting the
container. `wants_gpg_agent` finds the mount in
`/proc/mounts` and skips the launch, so the
container never starts a key-less agent of its own.

Because the container only borrows, the laptop must
have an agent running. An empty
`/run/user/1000/gnupg` means the host agent has
stopped: open a terminal on the laptop, or run
`gpgconf --launch gpg-agent`, to arm it. As on a
remote, import the public keys into the container
keyring so `git set-user` can map an address to a
key.

## SSH Keys

The `.pub` files in `~/.ssh/` are an allowlist.
`sync_ssh.sh` enforces it: keys in
`authorized_keys` that do not match any `.pub`
file are extracted to new `.pub` files (named
after the key comment) and removed from
`authorized_keys`. To revoke a key, delete its
`.pub` file and run sync.

## Markdown Lint

All markdown files in this repo must pass
`markdownlint` (`pnpm dlx markdownlint-cli`).
Nothing runs it automatically, so check before
committing. Key rules:

- 80-character line limit, code blocks included
  (tables are exempt); wrap genuinely unbreakable
  lines in a scoped `markdownlint-disable MD013`
  comment pair
- 2-space indent for nested lists
- Blank lines around headings, lists, code blocks
- No bare URLs; use `[text](url)` syntax
- No duplicate heading text within a file
- Files must end with a single newline
