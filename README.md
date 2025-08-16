# h42n42

OCaml in the browser!

> A project introducing the OCSIGEN framework, used to create rich applications in OCaml. The goal is to design a simulator of bugs escaping a dangerous virus.


## OCaml commands

```bash
opam exec -- dune build
opam exec -- dune exec h42n42

# watch mode
opam exec -- dune exec h42n42 -w

# launch utop, interactive shell
opam exec -- dune utop

# install a package, in this case a s-expression printer
opam install sexplib
```

## Thoughts

Untangling this OCaml shaped mess.

The OCSIGEN framework is some big group of modules, Eliom is also a fullstack framework? Not sure that the diff is, but Eliom docs tutorials align more with what the subject wants.


## Links

[getting started with Ocaml](https://ocaml.org/docs/tour-of-ocaml)
[getting started with Ocsigen](https://ocsigen.org/tuto/latest/manual/basics)
[using eliom](https://ocsigen.org/tuto/latest/manual/application)