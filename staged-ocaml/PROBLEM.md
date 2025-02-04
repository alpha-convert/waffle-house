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

We'd really like this generator to run *fast*. In [PBT in Practice](https://harrisongoldste.in/papers/icse24-pbt-in-practice.pdf), we found that
*"Developers test their properties “locally after each edit” (P2). Participants described strict time budgets for PBT—no more than “30 seconds” (P27) and as low as “50 milliseconds” (P11)—to ensure it would not slow down the build."* If tests are running **on file save** in-editor, we really need them to run blazingly fast!! This is an interactive program.

Unfortunately, this generator does not run nearly as fast as it could. The problem is that (as we'll see), it does a surprising amount of allocation. In theory, a generator for lists should allocate

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
Let's put this back into the definition of `gen_list_of`!
```ocaml
let gen_list_of g = fixed_point (
    fun gl ->
        let%bind n = Generator.size in
        if n <= 0 then return [] else
            create (fun ~size ~random ->
                let xs = generate (with_size gl (n-1)) ~size ~random in
                let x = generate g ~size ~random in
                x::xs
            )
)
```
Doing another inlining step for the last bind (and eliminating a beta reduction), and another for the last `return`
```ocaml
let gen_list_of g = fixed_point (
    fun gl ->
        create (fun ~size ~random ->
            let n = generate (Generator.size) ~size ~random in (* giving this its full name s: this isn't the argument `size` to create*)
            generate (
                if n <= 0 then (create (fun ~size ~random -> [])) else
                    create (fun ~size ~random ->
                        let xs = generate (with_size gl (n-1)) ~size ~random in
                        let x = generate g ~size ~random in
                        x::xs
                    )
                )
            ) ~size ~random
)
```

If we look at the definition of `Generator.size` [here](https://github.com/janestreet/base_quickcheck/blob/e429ad88cc4254dde71aee5adf17df3bd6a7521b/src/generator.ml#L22), it should be clear that `generate Generator.size ~size ~random = size` (the named variable of type `int` that's in scope from the surrounding `create`).

We can also lift the `if` outside the call to `generate`, to get:
```ocaml
let gen_list_of g = fixed_point (
    fun gl ->
        create (fun ~size ~random ->
            let n = size in
            if n <= 0 then generate (create (fun ~size ~random -> []))
            else generate (
                create (fun ~size ~random ->
                        let xs = generate (with_size gl (n-1)) ~size ~random in
                        let x = generate g ~size ~random in
                        x::xs
                    )
            )
        )
)
```
Inlining the last `generate/create` pairs, we get to our final version!
```ocaml
let gen_list_of g = fixed_point (
    fun gl ->
        create (fun ~size ~random ->
            let n = size in
            if n <= 0 then []
            else 
              let xs = generate (with_size gl (n-1)) ~size ~random in
              let x = generate g ~size ~random in
              x::xs
        )
)
```

Let's benchmark! With `core_bench` ([here](https://github.com/janestreet/core_bench)), we can run some tests.
All told, our program looks like this:

```ocaml
open Base_quickcheck.Generator;;
open Base_quickcheck.Generator.Let_syntax;;
open Core_bench;;

let gen_list_of g = fixed_point (
    fun gl ->
        let%bind n = size in
        if n <= 0 then return [] else
          let%bind xs = with_size ~size:(n-1) gl in
          let%bind x = g in
          return (x :: xs)
)

let gen_list_of_fast g = fixed_point (
    fun gl ->
        create (fun ~size ~random ->
            let n = size in
            if n <= 0 then []
            else 
              let xs = generate (with_size gl (n-1)) ~size ~random in
              let x = generate g ~size ~random in
              x::xs
        )
)

let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
  [
  Bench.Test.create_indexed ~name:"gen-list-basic" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n (gen_list_of bool)
  );
  Bench.Test.create_indexed ~name:"gen-list-fast" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n (gen_list_of_fast bool)
  );
]

```

And the output looks like:
```
┌──────────────────────┬──────────────┬─────────────┬────────────┬────────────┬─────────────┬──────────┐
│ Name                 │     Time/Run │     mWd/Run │   mjWd/Run │   Prom/Run │     mGC/Run │ mjGC/Run │
├──────────────────────┼──────────────┼─────────────┼────────────┼────────────┼─────────────┼──────────┤
│ gen-list-basic:10    │     343.64ns │     430.32w │            │            │     1.72e-3 │          │
│ gen-list-basic:50    │   2_145.81ns │   1_991.00w │      0.70w │      0.70w │     7.50e-3 │          │
│ gen-list-basic:100   │   3_415.84ns │   3_941.00w │      2.46w │      2.46w │    15.09e-3 │          │
│ gen-list-basic:1000  │  35_156.47ns │  39_041.00w │    156.49w │    156.49w │   149.46e-3 │  1.15e-3 │
│ gen-list-basic:10000 │ 514_013.33ns │ 390_041.00w │ 15_911.89w │ 15_911.89w │ 1_523.84e-3 │ 71.77e-3 │
│ gen-list-fast:10     │     188.50ns │     217.00w │            │            │     0.91e-3 │          │
│ gen-list-fast:50     │   1_023.09ns │     937.00w │      0.31w │      0.31w │     3.47e-3 │          │
│ gen-list-fast:100    │   1_964.74ns │   1_837.00w │      1.04w │      1.04w │     7.04e-3 │          │
│ gen-list-fast:1000   │  19_645.54ns │  18_037.00w │     68.87w │     68.87w │    68.97e-3 │  0.23e-3 │
│ gen-list-fast:10000  │ 278_188.07ns │ 180_037.00w │  7_417.04w │  7_417.04w │   698.81e-3 │ 24.09e-3 │
└──────────────────────┴──────────────┴─────────────┴────────────┴────────────┴─────────────┴──────────┘
```
The fast generator is about 2x as fast (in wall clock terms) as the basic generator. This is probably
because it allocates about half as much!

----


[1] I've simplified the definition by replacing the actual definition (which uses a `Staged.t`) with an equivalent one... a `'a Staged.t` is really just a `unit -> 'a`. This is a completely different sense of the word "staging" than the metaprogramming we're doing.

[2] See the `splittable_random` library for details, this is the same in Haskell QuickCheck.

[3] If you're struggling to understand this code (especially the code for `bind`), I'd highly recommend going to Haskell and writing the Monad instance for `data Foo a = MkFoo (Int -> Char -> a)`. Same concept here.

[4] I believe the only exception is when the function captures no free variables.

---
