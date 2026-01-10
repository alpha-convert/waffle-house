#!/bin/bash

dune clean; dune build
/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/test_fast_gen.exe &
PID=$!
../../magic-trace-bin attach -pid $PID