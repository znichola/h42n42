FROM ocaml/opam:debian-12-ocaml-5.2

# Install dune
RUN opam install dune -y

RUN sudo apt-get update && sudo apt-get install -y \
    libgmp-dev \
    pkg-config \
    libsqlite3-dev \
    libssl-dev \
    zlib1g-dev

RUN opam install eliom -y

RUN opam install ocsigen-ppx-rpc -y

# Set environment so dune is available
ENV PATH="/home/opam/.opam/default/bin:${PATH}"

WORKDIR /home/opam/app

EXPOSE 8080

COPY --chown=opam . .

RUN chmod +x docker_setup.sh

RUN "./docker_setup.sh"

ENTRYPOINT ["make" "install"]

CMD ["bash"]