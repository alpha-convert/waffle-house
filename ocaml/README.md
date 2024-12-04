Built on OCaml 4.10.3+trunk+flambda.

Build instructions:
1. `opam switch create 4.10.3+trunk+flambda`, and run the `$eval(...)` command it generates.
2. `git clone https://github.com/stedolan/ppx_stage` somewhere.
3. `opam install dune ocaml-migrate-parsetree ppx_tools_versioned`
4. `dune build` in the `ppx_stage` root directory.
5. In the `ocaml/` directory of this repo, `opam install base_quickcheck core_bench splittable_random core`
6. `opam pin add ppx_stage <directory where you put ppx_stage>`
7. `dune build` this project.
8. `dune exec fast_gen` to run the benchmarks.
9. For VSCode support, `opam install ocaml-lsp-server` (maybe?)

```
┌─────────────────────────┬──────────────┬─────────────┬────────────┬────────────┬─────────────┬──────────┐
│ Name                    │     Time/Run │     mWd/Run │   mjWd/Run │   Prom/Run │     mGC/Run │ mjGC/Run │
├─────────────────────────┼──────────────┼─────────────┼────────────┼────────────┼─────────────┼──────────┤
│ gentree:10              │     736.04ns │     897.41w │      0.25w │      0.25w │     3.45e-3 │  0.15e-3 │
│ gentree:50              │   3_213.77ns │   3_899.41w │      1.53w │      1.53w │    14.94e-3 │          │
│ gentree:100             │   6_157.94ns │   7_917.59w │      3.74w │      3.74w │    30.28e-3 │          │
│ gentree:1000            │  50_196.74ns │  66_063.54w │    155.85w │    155.85w │   252.43e-3 │  1.02e-3 │
│ gentree:10000           │ 822_247.06ns │ 945_927.97w │ 12_930.25w │ 12_930.25w │ 3_641.53e-3 │ 71.06e-3 │
│ gen-manual-unfold:10    │     137.38ns │     158.75w │            │            │     0.72e-3 │          │
│ gen-manual-unfold:50    │     425.30ns │     629.65w │      0.19w │      0.19w │     2.39e-3 │          │
│ gen-manual-unfold:100   │     809.71ns │   1_265.07w │      0.47w │      0.47w │     4.82e-3 │          │
│ gen-manual-unfold:1000  │   6_494.04ns │  10_321.76w │     23.35w │     23.35w │    39.38e-3 │          │
│ gen-manual-unfold:10000 │ 142_450.47ns │ 150_627.09w │  4_607.29w │  4_607.29w │   583.13e-3 │ 16.78e-3 │
│ gen-staged-splat:10     │     140.07ns │     158.11w │            │            │     0.72e-3 │          │
│ gen-staged-splat:50     │     425.35ns │     632.43w │      0.16w │      0.16w │     2.39e-3 │          │
│ gen-staged-splat:100    │     802.42ns │   1_251.96w │      0.33w │      0.33w │     4.81e-3 │          │
│ gen-staged-splat:1000   │   6_467.72ns │  10_311.12w │     23.98w │     23.98w │    39.37e-3 │          │
│ gen-staged-splat:10000  │ 135_700.62ns │ 150_660.23w │  4_708.70w │  4_708.70w │   580.78e-3 │ 12.27e-3 │
└─────────────────────────┴──────────────┴─────────────┴────────────┴────────────┴─────────────┴──────────┘

```
---

# What's the Problem?

Consider the following generator:

```ocaml
let gen_list_of g = fixed_point (
    fun gl ->
        let%bind n = size in
        if n <= 0 then return [] else
          let%bind xs = with_size ~size:(n-1) gl in
          let%bind x = g in
          return (x :: xs)
)
```

Given a generator `g : 'a Generator.t`, it builds a generator `gen_list_of g : ('a list) Generator.t`. This happens recursively. First, we bind the size parameter to `n`. `size : int Generator.t` is the generator that just returns the current size paramter. If `n` is `<= 0`, we return the empty list. Otherwise, we bind `xs` to a *recursive* generator call with size paramter `n-1` (if we didn't decrease the size paramter, our generator would never terminate). Then, we bind `x` to a use of the argument generator `g`, and return `(x :: xs)`.

Let's focus in on the `else` branch, where we do the real work.
```ocaml
let%bind xs = with_size ~size:(n-1) gl in
let%bind x = g in
return (x :: xs)
```

These `let%bind x0 = g0 in e`s desugar to calls to `Generator.bind g0 (fun x0 -> e)` via an OCaml preprocessor pass. So this code is really:
```ocaml
bind (with_size gl (n-1)) (fun xs ->
    bind g (fun x ->
        return (x::xs)
    )
)
```

To simplify this further, we have to look at the definition of `'a Generator.t ` in [generator.ml](https://github.com/janestreet/base_quickcheck/blob/master/src/generator.ml). There, we find the definition[1], along with two important functions. 
```ocaml
type 'a t = unit -> size:int -> random:Splittable_random.t -> 'a

let create (f : size:int -> random:Splittable_random.t -> 'a) : 'a t =
    fun () ~size ~random -> f ~size ~random

let generate (g : 'a t) (size : int) (random : Splittable_random.t)  =
    g () ~size ~random
```

A `'a Generator.t` (or just a `'a t`, when you're inside or have `Open`'d the `Generator` module) is a function that takes the size parameter, a random seed [2], and returns a `'a`. If you run this with different seeds and sizes, it gives you different `'a`s.

Note that `create` and `generate` are inverses of each other: `generate (create f) ~size ~random == f ~size ~random` and `create (fun ~size ~random -> generate g ~size ~random) == g`.

Let's take a look at the definitions of `return` and `bind`[3].

```ocaml
let bind t ~f =
  create (fun ~size ~random ->
    let x = generate t ~size ~random in
    generate (f x) ~size ~random)

let return x = create (fun ~size:_ ~random:_ -> x)
```

The first thing to say about this is that these function calls are *not inlined* by the OCaml compiler, as far as I can tell. Everywhere in the source of the generator you see a `bind` or a `return`, you jump to the code.

Next, we note that they both *immediately* call `create`, with a higher order function. In OCaml, calling a higher order function with a lambda as an argument *almost always* heap-allocates a closure to pass to the higher-order function [4]. So right away, some allocation is happening, very single iteration through the generator. But if we inline these function definitions and use the equations about `create` and `generate` we realized earlier, we can get rid of them!

```ocaml
bind (with_size gl (n-1)) (fun xs ->
    bind g (fun x ->
        return (x::xs)
    )
)
== (* inlining the first bind *)
create (fun ~size ~random ->
    let xs = generate (with_size gl (n-1)) ~size ~random in
    generate (
        (fun xs -> bind g (fun x -> return (x::xs))) xs (* note the explicit beta redex here!! *)
    ) ~size ~random
)
== (* beta reduction *)
create (fun ~size ~random ->
    let xs = generate (with_size gl (n-1)) ~size ~random in
    generate (
        bind g (fun x -> return (x::xs))
    ) ~size ~random
)
== (*inlining the second bind *)
create (fun ~size ~random ->
    let xs = generate (with_size gl (n-1)) ~size ~random in
    generate (
        create (fun ~size ~random ->
            let x = generate g ~size ~random in
            generate (
                (fun x -> return (x::xs)) x
            ) ~size ~random
        )
    ) ~size ~random
)
== (* beta reduction *)
create (fun ~size ~random ->
    let xs = generate (with_size gl (n-1)) ~size ~random in
    generate (
        create (fun ~size ~random ->
            let x = generate g ~size ~random in
            generate (
                return (x::xs)
            ) ~size ~random
        )
    ) ~size ~random
)
== (* rewrite with the create (generate ...) equation  *)
create (fun ~size ~random ->
    let xs = generate (with_size gl (n-1)) ~size ~random in
    let x = generate g ~size ~random in
    generate (
        return (x::xs)
    ) ~size ~random
)
== (* inline the definition of return *)
create (fun ~size ~random ->
    let xs = generate (with_size gl (n-1)) ~size ~random in
    let x = generate g ~size ~random in
    generate (
        create (fun ~size:_ ~random:_ -> x::xs)
    ) ~size ~random
)
== (* rewrite the create/generate equation again *)
create (fun ~size ~random ->
    let xs = generate (with_size gl (n-1)) ~size ~random in
    let x = generate g ~size ~random in
    x::xs
)
```

----


[1] I've simplified the definition by replacing the actual definition (which uses a `Staged.t`) with an equivalent one... a `'a Staged.t` is really just a `unit -> 'a`. This is a completely different sense of the word "staging" than the metaprogramming we're doing.

[2] See the `splittable_random` library for details, this is the same in Haskell QuickCheck.

[3] If you're struggling to understand this code (especially the code for `bind`), I'd highly recommend going to Haskell and writing the Monad instance for `data Foo a = MkFoo (Int -> Char -> a)`. Same concept here.

[4] I believe the only exception is when the function captures no free variables.

---
