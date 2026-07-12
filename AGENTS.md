# AI Agent Guide

Instructions for AI agents operating on machines
where these dotfiles are deployed.

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

## Available Tools

Key scripts in `~/bin/`:

| Script           | Purpose                      |
|------------------|------------------------------|
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
- Use `||` guards, not `&&` (breaks `set -e`)
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

## GPG Agent Forwarding

On remote hosts the private keys are never copied.
The laptop's `gpg-agent` is forwarded over SSH, so
signing happens on the laptop while `git` runs on
the remote.

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

Import the public keys on the remote. The forwarded
socket carries private keys by keygrip only -- it
has no user IDs -- so `git set-user` cannot match an
address until the matching public key is in the
keyring. `bootstrap.sh` imports the shipped
`files/.gnupg/*.asc`; by hand it is:

```sh
gpg --import ~/.gnupg/*.asc
```

Stop a stray `gpg` from clobbering the tunnel. Any
`gpg` call starts a local agent when none answers,
and that agent binds the standard socket -- unlinking
the forwarded one and leaving a key-less agent in its
place. The shipped `gpg.conf` sets `no-autostart` to
prevent this, so a forward gap makes `gpg` fail
loudly instead of replacing the tunnel. A local agent
is only ever started explicitly (`.bashrc` or
systemd), where one is actually wanted.

The forward only binds at connection time, so
reconnect after any change. To verify it is live:

- `gpg-connect-agent 'keyinfo --list' /bye` reports
  restricted mode, not a list of keygrips.
- `gpg --list-secret-keys` shows the keys with a `>`
  stub.
- `echo test | gpg --clearsign` succeeds and the
  pinentry prompt appears on the laptop.

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

## Sync

`sync.sh` creates symlinks in `$HOME` pointing
into `files/`. When a target already exists in
`$HOME`:

- **Regular file**: imported into `files/`, then
  replaced with a symlink.
- **Non-empty directory**: moved into `files/` and
  replaced with a symlink.
- **Existing symlink**: relinked if it points
  somewhere else.

`sync_ssh.sh` runs automatically after every sync.

To re-sync after changes:

```sh
cd ~/projects/dotfiles
./sync.sh
```

`bootstrap.sh` does the same but also initialises
submodules and runs `git reset --hard` afterward.

## SSH Keys

The `.pub` files in `~/.ssh/` are an allowlist.
`sync_ssh.sh` enforces it: keys in
`authorized_keys` that do not match any `.pub`
file are extracted to new `.pub` files (named
after the key comment) and removed from
`authorized_keys`. To revoke a key, delete its
`.pub` file and run sync.

## Markdown Lint

This repo enforces `markdownlint` on all markdown
files via `pnpx markdownlint-cli`. Key rules:

- 80-character line limit (tables are exempt)
- 2-space indent for nested lists
- Blank lines around headings, lists, code blocks
- No bare URLs; use `[text](url)` syntax
- No duplicate heading text within a file
- Files must end with a single newline
