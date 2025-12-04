#!/bin/bash
set -e

MNT="/home/opam/mnt"
DEV_FILES=(
  "h42n42.eliom"
  "static/css/h42n42.css"
)

for f in "${DEV_FILES[@]}"; do
  src="$MNT/$f"
  dest="$f"     

  if [ -f "$src" ]; then
    cp "$src" "$dest"
  else
    echo "Warning: '$src' not found in /home/opam/mnt"
  fi
done

chown -R opam:opam .

eval "$(opam env)"
dune build

if [ "$@" ]; then
  exec "$@"
else
  make test.opt
fi
