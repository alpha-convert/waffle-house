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