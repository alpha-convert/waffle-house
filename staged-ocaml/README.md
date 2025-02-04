Built on BER MetaOCaml 4.14.1.

Build instructions:
1. Ensure you are on an x86_64 machine. I built this using an EC2 t2.large instance.
2. `opam switch create 4.14.1+BER`, and run the `$eval(...)` command it generates.
3. `opam install base_quickcheck splittable_random core`
4. `dune build`