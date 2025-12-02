# Reviewer A

### Q1) Can you clarify the novelty of your paper? Does it introduce any optimization from the multi-stage programming not known before?

The main novelty of this work lies in applying staging to PBT. While staging
techniques are well established, their application to the abstractions and
performance bottlenecks of PBT libraries has not been explored, nor is it
straightforward. Our paper is intended to promote staging as a tool in the PBT
developer’s toolkit by showing that it can erase abstraction overhead, leading
to substantial performance improvements.

Prior to this work, neither abstraction overhead nor
sampling costs were viewed as major targets for optimization in PBT. As
evidence, we point to SOTA libraries like `Base_quickcheck`, which is highly
performance sensitive yet retains design choices (monadic combinators, expensive
randomness) that introduce significant overhead.

Additional novelty lies in Section 3.7, where we stage type-derived generators.
Unlike most staged libraries, which require users to understand metaprogramming,
our approach is fully automatic. Since type-derived generators are constructed
at compile time, they can be staged without altering user experience. This is a
rare example of staging "for free."

### Q2) Can you elaborate on the end-to-end effectiveness of your proposed solution?

The end-to-end effectiveness of our solution depends on (a) the complexity 
of the inputs being generated, and (b) the amount of time generation takes 
relative to other parts of the testing process—most obviously, running the 
system on the generated input. 

In general, more complex generators contain more calls to bind that are 
fused away using the Allegro technique; therefore, more complex generators 
see a larger speedup. Figure 15 showcases this relationship. 

The effectiveness of efficient input generation on total testing time is 
dependent on how long everything that isn’t input generation takes. In systems 
where running the tests themselves is slow, speeding up input generation won’t 
have as large an impact; in systems where testing is fast, it will constitute a 
major speedup. Our end-to-end tests on bug-finding speed, shown in Fig. 17 and 
Fig. 18, show the time it takes for PBTs to find bugs in mutated programs. In 
these examples, faster input generation has a measurable end-to-end impact on 
all of our benchmarks—up to 2.65X using staging alone, and 3.40X in combination 
with fast randomness.

### Q3) What would it take to implement type-derived generators in Scala? Why did you decide not to implement it?

---

# Reviewer B

Reviewer B also asks (Q2) if the testing-time speedups are a benefit, given (a) the time required to compile the staged code, and (b) the relative balance between input-generating and property-running durations in practice.

These are both excellent points...

For (a), we do not believe that this is an issue in practice, for two reasons.

1. Generator code changes extremely infrequently compared to code being
tested, and the generator metaprogram needs to be re-run and the output code
recompiled only as the generator itself changes. This is somewhat different from
many other uses of run-time metaprogramming, where the application code itself is
written as a metaprogram. Our intended mode of usage therefore is more like compile time metaprogramming
than run-time metaprogramming, where programmers save the code output to disk to cache it.
2. Generators are quite small, and compile quite quickly.

> Typos on l379, l475, l621, l653, l718, l824

p4: It's odd that Figure 4 appears before Figure 3.

: "returns a code" should be "returns code"

: "a observation"

: "a 'a code" - perhaps you mean "a value of type 'a code"?

> l119: I'm curious whether OCaml 5 might benefit from using it's native
effect handlers in place of a monadic generator DSL.

We are also now curious about this! Very interesting idea, direct-style generators
could potentially be very performant and also have the benefit of being more idiomatic.

> l989: You have conjectured that because GHC is set up to perform aggressive optimisations without staging then it is likely to benefit less from the kind of optimisations you exploit. It would be worth investigating to what extent this is indeed the case. Given that GHC’s QuickCheck is the canonical PBT framework it seems particularly worthwhile to perform further experiments with it. I wonder to what extent it would be possible to disable some of GHC’s aggressive inlining, both in order to assess how much it is really paying off, and to compare its robustness to your staging approach.

This is a fair point. Our conjecture is based on anecdotal evidence; one of the authors — an experienced Haskell developer — manually applied some of Allegro’s optimizations to a few Haskell generators, and they found that they could really only manage to make performance worse, not better. This is nowhere near a proof, but it discouraged us from exploring that path in the short term. We would be happy to mention this anecdotal experience and/or go into more detail about wanting to do this experiment as future work

<!-- ``The authors need to use more workloads and justify this more clearly.'' You're saying... give us *more* workloads? -->

<!-- These benchmarks are relatively challenging to build: one needs many a program, many properties, and many mutants of varying known difficulties -->

<!-- 
The second criticism is with the evaluation. It is unclear to me if, in the software development cycle, the proposed improvement will provide any actual benefit for two main reasons. First, the compiler time is not taken into account. Multi-stage programming adds a runtime code generation time; the extent to which it is taken into account is unclear. It has an overhead that can be amortized if the computation itself is very time-consuming. The authors need to clarify if this time is taken into account. Second, based on Amdahl's Law, does the proposed improvement bring actual benefits in practice? RQ2 shows results for finding bugs in the Etna platform. However, it is still unclear how many practical applications one would see in which a massive proportion of overhead for the testing infrastructure vs. the time each function itself takes. The authors need to use more workloads and justify this more clearly. -->

# Reviewer C

1. Can you provide an example of how the recursive generator API in Section 3.6 is used?
Yes, it's used in Figure 3 --- we can include a figure down at section 3.6 with a small example in the camera ready.

2. How were the experimental benchmarks chosen?

We used the subset of the pre-existing Etna suite of benchmarks. Etna was
designed exactly for this purpose: to test the bugfinding capabilities of
competing PBT generators.  There are two benchmarks from the original Etna we
did not use. One tests Red-Black trees, and the other tests a lambda calculus
typed with System FSub, a more sophisticated type system.  We felt that the RBT eval was
redundant with the BTS eval we already used: the generators are very similar.
We chose not to use the FSub eval for two reasons. First, it had not been implemented
in OCaml, and second, we felt this would be redundant with the STLC
evals. The FSub generator is even more complex with more combinators than the STLC one, but the testing code and properties are essentially the same:
we would see an exaggerated version of the speedups in the STLC eval.

3. What do you mean by "semantically identical", and are the generators also syntactically similar?

Yes, the AllegrOCaml and Base_quickcheck generors are as you imagine: essentially syntactically identical, modulo
some extra syntactic cruft for staging. We plan to submit all of our code with the artifact evaluation, but for now, we
include an example from our evals of a generator and its staged counterpart below the fold.

By "semantically identical", we mean that given the same random seeds, the two
generators produce the same generated output.  This property is important
because it guarantees that all of our bug-finding speedups are solely
attributable to the improved performance of staged generators, and not because
the staged generators happen to luckily create bug-squashing outputs. The
sequence of outputs is the same between the staged and unstaged versions, the staged
generators just produce them faster.

We further note that this is not an obvious or simple property to maintain:
staged and unstaged programs can look syntactically similar but behave
non-equivalently, especially in the presence of effects (for example, `let x =
print "hi" in x;x` and `let x = .<print "hi">. in .<$x;$x>. --- the former
prints once, the latter twice). Section 3.4 is essentially about ensuring that
programmers need not worry about this, and can write their generators in a
manner that is syntactically as similar as possible to the non-staged versions.

```
let rec gen ~(lo: int) ~(hi: int)  =
  let%bind sz = size in
  let should_stop = lo >= hi || sz <= 1  in
  if should_stop
    then return E
  else
    weighted_union [
      (1., return E);
      (float_of_int sz , (
        let%bind k = int_inclusive ~lo ~hi in
        let%bind v = Nat.quickcheck_generator_parameterized bst_bespoke_limits in
        let%bind left = with_size ~size_c:(sz / 2) (gen ~lo:lo ~hi:(k - 1))  in
        let%bind right = with_size ~size_c:(sz / 2) (gen ~lo:(k + 1) ~hi:hi) in
        return (T (left, k, v, right))  
      ))
    ]

let staged_quickcheck_generator (lo: int code) (hi: int code) : tree code G.t =
  recursive (.< (.~lo, .~hi ) >.) 
  (fun go lohi -> 
    let%bind sz = size in
    let%bind (lo, hi) = split_pair lohi in
    let%bind should_stop = split_bool .< .~hi <= .~lo || .~sz <= 1 >. in
    if should_stop
      then return .< E >.
    else
      weighted_union [
        (.< 1. >., return .< E >.);
        ((G.C.i2f sz), (
          let%bind k = int_inclusive ~lo ~hi in
          let%bind v = Nat.staged_quickcheck_generator_sr_t (G.C.lift bst_bespoke_limits) in
          let%bind left = with_size ~size_c:(G.C.div2 sz) (recurse go .<(.~lo, .~k - 1) >.) in
          let%bind right = with_size ~size_c:(G.C.div2 sz) (recurse go .<(.~k + 1, .~hi) >.) in
          return (.< T (.~left, .~k, .~v, .~right) >.)))
      ]
  )
```
