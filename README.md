# h42n42

Simulate the life of a population of creatures threatened by a terrifying virus.

Also, OCaml in the browser!

> A project introducing the OCSIGEN framework, used to create rich applications in OCaml. The goal is to design a simulator of bugs escaping a dangerous virus.


Build, and then launch the container.

```zsh
docker build -t h42n42 .
docker run --rm -it -p 8080:8080 -v .:/home/opam/mnt h42n42:latest bash -c "make test.byte"
```

The latest version of the app is deployed with onrender on [h42n42.onrender.com](https://h42n42.onrender.com/)

## Ocaml, Eliom and Ocsigen

Ocaml is a language, Eliom is a fullstack (+modile) framework, Oscigen is the project name.

The project is generated using `eliom-distillery -name h42n42 -template app.exe -target-directory .` this is a setup with dune as the build system, see [Dockerfile](./Dockerfile) for prerequisits. The process generates a bunch of files. For the project only the [h42n42.eliom](./h42n42.eliom) and [static/css/h42n42.css](./static/css/h42n42.css) were modified. All code lives in one file, the build system was too annoying to get it working as multiple modules.

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

## Utop commands

```utop
(* load a file to run it's functions *)
#use "bin/main.ml"
```


## Eliom comands

See [README_ELIOM.md](/README_ELIOM.md) for mroe details.

```bash
# Build the website
make all

# Put website files in local/var/www/h42n42
make install

# Start the server
make run

# Build and run the server
make test.byte
```


## Thoughts

Untangling this OCaml shaped mess.

The OCSIGEN framework is some big group of modules, Eliom is also a fullstack framework? Not sure that the diff is, but Eliom docs tutorials align more with what the subject wants.

## Links

- [getting started with Ocaml](https://ocaml.org/docs/tour-of-ocaml)
- [getting started with Ocsigen](https://ocsigen.org/tuto/latest/manual/basics)
- [using eliom](https://ocsigen.org/tuto/latest/manual/application)
- [Html.F vs HTML.D](https://ocsigen.org/eliom/latest/manual/clientserver-html#unique)
- [demo_read.eliom](https://github.com/ocsigen/ocsigen-start/blob/master/template.distillery/demo_react.eliom)
- [js of ocamel](https://ocaml.org/p/js_of_ocaml/3.10.0/doc/js_of_ocaml/Js_of_ocaml/Js/index.html)

## Installing OCaml on school computers

```

Run bash line to download opam to a folder in sgoinfre, put this in `PATH` by modifying the `.zshrc`.

```zsh
bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh)"
```

Then init opam by telling it where the root should be so it's got the space to install.

```zsh
opam init --root="~/sgoinfre/.opam"
```

Add this line to `.zshrc` to tell opam where it's root is.

```zshrc
export OPAMROOT=/sgoinfre/znichola/.opam
```

But all this is useless because eliom requiers system libs the school does not include.

### Running in Docker

The dockerfile is setup so it has everything installed and building the docker image also builds the project internally, the entrypoint is therefore `make test.byte` which launches the test server. The [entrypoint](./docker_entrypoint.sh) copies the two dev files to the dev folder in the contianer, so rerunning rebuilds also. (TODO see about using `make install` and running an apache instance to serve the static files).

```zsh
docker build -t ocaml_dev_image .
docker run --rm -it -p 8080:8080 -v .:/home/opam/mnt ocaml_dev_image:latest bash -c "make test.byte"
```

## Notes on subject

### Creet

- if no more creets game over

- if creet walks into river (or is placed into river) it gets sick

- creet spontaneously reproduces if there is at least one healthy creet

- a healthy creet will never die

- possible to grab move creet

- dropping a creet on a hospital will heal it, (only dropping heals)

- a grabbed creet cannot get contaminated, it's invulnerable

- a creet moves in a straight line, and randomly changed direction

- creets rebound from the edges realistically

- contaminated creets are 15% slower and and have a color

- there is a 2% risk of contamination on contact for each interation,
(no rebound between creets)

- when a creet gets sick it has a 10% chance of being beserk!

    - a bezerk creet  has a different color, it's slowly grows in size
        (4x by the end)

- when a creet gets sick it has a 10% chance of being mean
    - a mean cree has a different color, 15% smaller and runs towards
        healthy creets

- creet base speed increases over time

- sick creets have a lifetime, afterwhich they will die



