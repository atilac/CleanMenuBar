#!/bin/sh
# Publishes site/ to monobit.com.br/cleanmenubar over SSH.
#
# Authentication is by key, set up once with:
#   ssh-keygen -t ed25519 -f ~/.ssh/hostgator -N ""
#   ssh-copy-id -i ~/.ssh/hostgator.pub -p 22 atilav48@ftp.atilac.net
#
# --delete makes the server match site/ exactly, so anything removed from the
# generator disappears upstream instead of lingering. There are no exclusions:
# build-site.py refuses to finish if site/ holds anything that is not meant to
# be served, so the folder and the published site are the same thing by
# construction. Documentation about the site lives in docs/site-build.md.
set -e

cd "$(dirname "$0")/.."
python3 Tools/build-site.py

rsync -az --delete \
  -e "ssh -i ~/.ssh/hostgator -p 22" \
  site/ atilav48@ftp.atilac.net:monobit.com.br/cleanmenubar/

echo "published: https://monobit.com.br/cleanmenubar/"
