open Util.Limits;;
open Base;;
open Type;;
open Fast_gen;;
open Nat;;
module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
open G
open Let_syntax
open Codelib;;

type t = tree [@@deriving sexp, quickcheck]


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
          let%bind v = Nat.staged_quickcheck_generator_sr_t (G.C.lift 1000) in
          let%bind left = with_size ~size_c:(G.C.div2 sz) (recurse go .<(.~lo, .~k - 1) >.) in
          let%bind right = with_size ~size_c:(G.C.div2 sz) (recurse go .<(.~k + 1, .~hi) >.) in
          return (.< T (.~left, .~k, .~v, .~right) >.)))
      ]
  )

let staged_code =
  staged_quickcheck_generator (G.C.lift 0) (G.C.lift 1000)

let make_quickcheck_generator () =
  G.jit ~extra_cmi_paths:["/home/jcutler/Documents/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte"; "/home/jcutler/Documents/waffle-house/staged-ocaml/_build/default/test/strategies/BST/.BST.objs/byte"] staged_code

let quickcheck_generator = make_quickcheck_generator ()
