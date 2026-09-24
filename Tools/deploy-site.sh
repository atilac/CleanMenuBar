#!/bin/sh
# Publishes site/ to monobit.com.br/cleanmenubar over SSH.
#
# Authentication is by key, set up once with:
#   ssh-keygen -t ed25519 -f ~/.ssh/hostgator -N ""
#   ssh-copy-id -i ~/.ssh/hostgator.pub -p 22 atilav48@ftp.atilac.net
#
# --delete makes the server match site/ exactly, so files removed from the
# generator disappear upstream instead of lingering. README.md is excluded
# because it documents the build for contributors and has no business being
# served; it is removed from the server separately if it ever lands there.
set -e

cd "$(dirname "$0")/.."
python3 Tools/build-site.py

rsync -az --delete --exclude 'README.md' \
  -e "ssh -i ~/.ssh/hostgator -p 22" \
  site/ atilav48@ftp.atilac.net:monobit.com.br/cleanmenubar/

echo "published: https://monobit.com.br/cleanmenubar/"
