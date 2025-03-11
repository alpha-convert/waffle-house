#!/bin/bash

# Run dune clean
echo "Running 'dune clean'..."
dune clean

# Run dune build
echo "Running 'dune build'..."
dune build

# Unpin the package
echo "Running 'opam unpin .'..."
opam unpin .

# Delete line 21 of fast_gen.opam
echo "Deleting line 21 of fast_gen.opam..."
sed -i '21d' fast_gen.opam

# Pin the package
echo "Running 'opam pin .'..."
opam pin .

echo "All operations completed successfully."