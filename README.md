# Dotfiles

Personal dotfiles managed via symlinks into `$HOME`.

## Quick Start

Clone and bootstrap:

```sh
git clone <url> dotfiles
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` initialises submodules, runs sync,
then does `git reset --hard` to discard any files
that sync imported from an existing home directory.

To re-sync without resetting:

```sh
./sync.sh
```

## How Sync Works

`sync.sh` finds every file under `files/` and
creates a corresponding symlink in `$HOME`.

When a target already exists in `$HOME`:

- **Regular file**: copied into `files/`, replacing
  the repo version, then symlinked. This imports
  local changes into the repo.
- **Non-empty directory**: moved into `files/` and
  replaced with a symlink.
- **Existing symlink**: relinked if it points
  somewhere else.

Parent directories are created as needed.

## SSH Key Management

`sync_ssh.sh` runs after every sync. The `.pub`
files in `~/.ssh/` act as an allowlist of
acceptable keys:

- Keys in `authorized_keys` that match a `.pub`
  file are kept.
- Keys that do not match any `.pub` file are
  removed from `authorized_keys` and extracted
  to a new `.pub` file (named after the key
  comment). Deleting that `.pub` file prevents
  the key from being re-authorized.
- If `authorized_keys` is empty or missing, it
  is seeded from a set of default `.pub` files.

## Managed Files

Key configurations symlinked from `files/`:

| File          | Purpose                       |
|---------------|-------------------------------|
| `.bashrc`     | Shell config, PATH, aliases   |
| `.bash/`      | Prompt and local shell config |
| `.profile`    | Login shell setup             |
| `.gitconfig`  | Git identity, aliases, colors |
| `.vimrc`      | Vim configuration             |
| `.vim/`       | Vim runtime files             |
| `.tmux.conf`  | Tmux configuration            |
| `.screenrc`   | GNU Screen configuration      |
| `.pbuilderrc` | Debian package builder        |

See `files/` for the complete list.

## Utilities

`files/bin/` contains shell scripts available as
`~/bin/` after sync. Highlights:

| Script          | Purpose                       |
|-----------------|-------------------------------|
| `x`             | Find and run workspace entry  |
| `icdiff`        | Side-by-side colored diff     |
| `git-icdiff`    | icdiff as git diff driver     |
| `colorize`      | Syntax-highlight any file     |
| `pcat`          | Filter and colorize pipelines |
| `vcs_update`    | Pull and rebase any VCS repo  |
| `mkgit`         | Init repo with remote         |
| `repo-find`     | Find files in repo workspace  |
| `repo-grep`     | Grep across repo workspace    |
| `repo-list`     | List git repos recursively    |
| `repo-root`     | Print repo workspace root     |
| `tmux-reattach` | Attach or create tmux/screen  |
| `tmux-here`     | Per-directory tmux session    |
| `sshscreen`     | SSH with auto tmux attach     |
| `moshscreen`    | Mosh with auto tmux attach    |
| `sshloop`       | Reconnecting SSH wrapper      |
| `getpem`        | Extract public key from TLS   |
| `apt_upgrade`   | Full apt upgrade and cleanup  |

See `files/bin/` for the full set of scripts.

## Submodules

Third-party dependencies in `3rd-party/`:

- **icdiff** -- side-by-side colored diff tool
- **editorconfig-vim** -- EditorConfig for Vim
- **vim-bitbake** -- BitBake syntax
- **vim-flatbuffers** -- FlatBuffers syntax
- **vim-hcl** -- HCL syntax
- **leg.vim** / **peg.vim** -- PEG syntax
- **cocci-syntax** -- Coccinelle syntax

Update all submodules:

```sh
git submodule update --init
```

## Auto-Update

`run.sh` wraps `update.sh` and `sync.sh` for
unattended use. `update.sh` fetches from the
tracking remote and exits early if nothing
changed. Otherwise it stashes local changes,
rebases, updates submodules, pops the stash,
then runs `sync.sh`.

## System Configs

`system/etc/` contains system-level configurations
not symlinked automatically:

- `rc.local` -- tmpfs caching for browser profiles
- `auto.master.d/` -- autofs mount definitions
