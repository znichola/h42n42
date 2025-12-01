#!/bin/bash
set -e

eval $(opam env)
opam install .
dune build