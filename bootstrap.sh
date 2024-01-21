#!/bin/sh

set -eu
cd "$(dirname "$0")"
git submodule update --init
./sync.sh
git reset --hard
