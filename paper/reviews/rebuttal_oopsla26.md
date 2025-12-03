Thank you for your comments and questions! We begin with brief to some
high-level concerns, then address all reviewer questions in detail
"below the fold."

## Reviewer A asks us to clarify the novelty of our paper (Q1).

Our first novel contribution is the identification of previously
unrecognized sources of inefficiency in PBT: DSL abstraction overhead
and sampling costs.  Prior work on speeding up PBT has never targeted
these. Indeed, even production-grade PBT libraries like
Base_quickcheck, which are optimized for performance using imperative
language features, retain monadic combinators and expensive
randomness.

A second source of novelty is the application of staging to PBT
generators. While using staging to eliminate the abstraction overhead
of DSLs is well studied, it has never before been applied to PBT.
While staging techniques for optimizing DSLs are well established,
their application to PBT is novel. Indeed, doing so posed some
nontrivial technical challenges. Sections 3.5 and 3.6 describe how
simply applying naive staging is not sufficient: more sophisticated
techniques must be employed to make programming in a staged generator
DSL ergonomic.

Finally, our method for synthesizing staged generators from type
definitions deploys multi-stage programming in an unusually strong
form. Type-derived generators are standard in the PBT literature, but
type-derived *staged* generators are two-level metaprograms: from a
type we generate code that generates a PBT generator.

## Reviewers A and C ask about our benchmarks, how we chose them, and the balance between testing time versus generation time in practice

Our evaluation uses Etna, a standard benchmark suite for comparing the
bug-finding speed of PBT generators. Etna includes both simple
generators (e.g., BST) and sophisticated ones (well-typed STLC terms),
and properties that range from cheap-to-check (BST operations maintain
the BST invariant) to expensive (well-typed STLC programs don't get
stuck). In all of these cases, we find a consistent end-to-end
bug-finding speed improvement from Allegro.

Of course, real world uses of PBT will vary even more widely than
those in Etna.  Characterizing what proportion of testing time is
spent on test generation in real-world PBT workloads definitely merits
further study, but we view this as future work.

We did omit two Etna of the benchmarks: Red-Black trees–which we
thought were redundant with our BST evaluation–and System
FSub–redundant with STLC, and not implemented in OCaml.

## Reviewer A asks about compilation-time overhead.

All the generators from the evaluation compile in under 55ms, which is
amortized across all the tests, each of which takes on the order of
seconds. Moreover, generators change infrequently compared to
application code, so a production Allegro implementation could cache
compiled generators, avoiding compilation at test time almost
entirely.

## Reviewer B asks if our work can be used to bridge the performance gap between PBT and fast hand-rolled fuzzers

[BCP: This part of the response still feels mushy, in part because I
don't think we've really gotten clear in our minds what the real
question is or what our real answer is.]

Our work speaks to part of this question. 

Hand-coded fuzzers that construct inputs satisfying specific
structural and semantic constraints are performing precisely the same
task that PBT generators are designed for. Hand-coded fuzzers might be
faster than PBT generators if users choose to optimize them
aggressively, but ideally such optimizations should not need to be
done manually. Our hope is that Allegro (and other advances from the
PBT literature) can make PBT generators fast enough that developers
could use them as highly-performant fuzzers, even though they are
expressed in a higher-level language that is easier to write in and
reason about. 

(The question gets a bit less clear when considering fuzzers that use
mutation and other techniques to obtain interesting inputs, rather
than a hand-coded program, although ideas in papers like Coverage
Guided Property-Based Testing and Parsing Randomness may provide paths
forward in those domains as well.)

## Reviewer C inquires if the staged generators are syntactically similar to their unstaged counterparts, and asks for clarification about the term "semantically identical"

Indeed, the staged and unstaged generators are syntactically very
similar, modulo some extra cruft required by MetaOCaml and Scala to
write staged code. 

By "semantically identical" we mean that, given the same random seed,
both produce the same outputs. This ensures that our speedups come
purely from faster generation, not from lucky choices of random test
generation that happen to find bugs sooner.

-------------------------------------------------------------------------

# Reviewer A:

##  Q2) Can you elaborate on the end-to-end effectiveness of your proposed solution?

Our evaluation uses Etna, a standard platform for evaluating the
bug-finding speed of PBT generators. It was designed as a testbench
for comparing generator strategies against each other, and, to our
knowledge, no more comprehensive benchmark suite exists for this
purpose. Our results show consistent speedups across Etna's tasks,
with generation time translating directly to faster bug finding.

Characterizing the proportion of testing time spent on generation
across real-world PBT workloads is a question that definitely merits
further study; we view this as future work outside the scope of this
paper.

As for the compilation time of emitted generator code, we do not
believe this is an issue for two reasons. First, our metaprogrammed
generators compile very quickly: a average of 33ms for Bool List up to
54ms for STLC, plus or minus 5ms for each (a full table can be found
at the bottom of our response). Amortized across testing multiple
properties (which usually take seconds each), this cost is
negligible. Second, generators change infrequently compared to code
being tested, and the generator really only needs to be recompiled
when it changes. A production instantiation of Allegro could let
programmers cache generator code, avoiding compilation at testing time
almost completely.

## Q3) What would it take to implement type-derived generators in Scala? Why did you decide not to implement it?

We see no fundamental barrier to implementing type-derived staged
generators in Scala. Indeed, the ScalaCheck-derived project already
uses Scala's reflection features to type-derive standard (unstaged)
ScalaCheck generators. Adapting this approach to emit ScAllegro would
require engineering effort, but we anticipate no obstacles beyond
that. We chose to implement our type-derived generators in OCaml
simply because none of the authors are Scala experts: we are much more
familiar with OCaml, so we chose to focus our implementation efforts
there.

In the camera ready, we will make it clear earlier that we only
implemented type-derived generators in AllegrOCaml.

-------------------------------------------------------------------------

# Reviewer B:

## l119: I'm curious whether OCaml 5 might benefit from using it's native
effect handlers in place of a monadic generator DSL.

Now we are also curious about this!  It's a very interesting idea:
direct-style generators could potentially be very performant and more
idiomatic.

## l639: Testing is all well and good, but have you not also considered trying to construct a more rigorous proof that AllegrOCaml is correct by program transformation / calculation?

We had not considered this, but it would be interesting to try.

## l751: Given that MetaOCaml is compatible with OCaml 5, why are you still using OCaml 4?

We were not aware that MetaOCaml was now compatible with OCaml 5 -- this is good
to know!  When we began the project earlier this year, the MetaOCaml homepage
instructed users to install a version compatible with OCaml 4.14.1, which is
what we did (it has since been updated to recommend 5.3.0).

## l989: You have conjectured that because GHC is set up to perform aggressive optimizations without staging then it is likely to benefit less from the kind of optimizations you exploit. It would be worth investigating to what extent this is indeed the case. Given that GHC’s QuickCheck is the canonical PBT framework it seems particularly worthwhile to perform further experiments with it. I wonder to what extent it would be possible to disable some of GHC’s aggressive inlining, both in order to assess how much it is really paying off, and to compare its robustness to your staging approach.

This is a fair point. Our conjecture is based on anecdotal evidence;
one of the authors — an experienced Haskell developer — manually
applied some of Allegro’s optimizations to a few Haskell generators,
and they found that they could really only manage to make performance
identical or worse. This is nowhere near a proof, but it discouraged
us from exploring that path in the short term. We would be happy to
mention this anecdotal experience and/or go into more detail about
wanting to do this experiment as future work.

-------------------------------------------------------------------------

# Reviewer C:

## 1. Can you provide an example of how the recursive generator API in Section 3.6 is used?

Yes, it's used in Figure 3. We can include a figure down at Section
3.6 with a small example in the next version.

## 2. How were the experimental benchmarks chosen?

We used benchmarks from Etna, a platform specifically designed to test
the bug-finding capabilities of competing PBT generators.  There are
two benchmarks from the original Etna we did not use. One tests
Red-Black trees, and the other tests a lambda calculus typed with
System FSub—a more sophisticated type system. We felt that the RBT
eval was redundant with the BTS eval we already used: the generators
are very similar, and so were the results. We chose not to use the
FSub eval for two reasons: first, it had not been implemented in
OCaml; second, we felt it would be redundant with the STLC evals. The
FSub generator is even more complex with more combinators than the
STLC one, but the testing code and properties are essentially the
same: we would see an exaggerated version of the speedups in the STLC
eval.

## 3. What do you mean by "semantically identical", and are the generators also syntactically similar?

Yes, the AllegrOCaml and Base_quickcheck generators are as you
imagine: essentially identical syntactically, modulo some extra cruft
for staging. We plan to submit all of our code with the artifact
evaluation, but, for now, we include an example from our evals of a
generator and its staged counterpart at the bottom of this response.

By "semantically identical", we mean that, given the same random
seeds, the two generators produce the same generated output.  This
property is important because it guarantees that all of our
bug-finding speedups are solely attributable to the improved
performance of staged generators, and not because the staged
generators happen to luckily create bug-squashing outputs. The
sequence of outputs is the same between the staged and unstaged
versions; the staged generators just produce them faster.

This is not an obvious property or an easy one to maintain: staged and
unstaged programs can look syntactically similar but behave
non-equivalently, especially in the presence of effects (for example,
`let x = print "hi" in x;x` and `let x = .<print "hi">. in
.<$x;$x>. -- the former prints once, the latter twice). Section 3.4 is
essentially about ensuring that programmers need not worry about this
and can write their generators in a manner that is syntactically as
similar as possible to the non-staged versions.

## 4. Why was BST (Repeated Insert) not used for the ScAllegro experiments in Figure 16?

We picked a representative from each category of generators: trees,
lists, and STLC terms, representing low, medium, and high numbers of
binds, respectively.  We anticipate BST (Repeated Insert) would see a
slightly smaller than the other generators speedup due to its lower
number of binds, and we would be happy to include this information in
a revision. Our goal in this evaluation subsection was not to
point-by-point reproduce the AllegrOCaml evaluation in ScAllegro, but
simply to demonstrate that the performance improvements of the Allegro
technique are portable across languages.

## I found the repeated shifting of focus between OCaml and Scala to be distracting. An alternative approach might have been to describe the entirety of the approach for OCaml, and then summarize the Scala-specific differences.

Thanks for this feedback. We'll try to further isolate the discussion
of Scala to just the intro and the bits of the evaluation where we
evaluate ScAllegro.

## On a related note, the paper might be easier to read if there was a single table / figure that summarized the types of various values and objects used throughout the paper. I found myself making this list as I read the paper.

This is a great idea and a good use of the extra space in a
camera-ready version.

-------

# Generator Compilation Times


|     Generator     | Compilation Time |
|-------------------|------------------|
|Bool List          |33.183ms          |
|BST Repeated Insert|45.453ms          |
|BST Type           |46.051ms          |
|BST Single Pass    |50.147ms          |
|STLC Type          |44.663ms          |
|STLC Bespoke       |53.699ms          |

-------

# Unstaged and Staged Single-Pass BST Generators

## Unstaged
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
        let%bind v = Nat.quickcheck_generator_parameterized 1000 in
        let%bind left = with_size ~size_c:(sz / 2) (gen ~lo:lo ~hi:(k - 1))  in
        let%bind right = with_size ~size_c:(sz / 2) (gen ~lo:(k + 1) ~hi:hi) in
        return (T (left, k, v, right))  
      ))
    ]
```

## Staged
```
let gen (lo: int code) (hi: int code) : tree code G.t =
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
          let%bind v = Nat.staged_quickcheck_generator_sr_t (G.C.lift 1000) in
          let%bind left = with_size ~size_c:(G.C.div2 sz) (recurse go .<(.~lo, .~k - 1) >.) in
          let%bind right = with_size ~size_c:(G.C.div2 sz) (recurse go .<(.~k + 1, .~hi) >.) in
          return (.< T (.~left, .~k, .~v, .~right) >.)))
      ]
  )
```
