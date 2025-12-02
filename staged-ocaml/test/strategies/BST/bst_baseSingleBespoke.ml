(* open Util.Limits *)
open Core;;
open Type;;
open Fast_gen;;
open Fast_gen.Bq_generator;;

module BQ = Fast_gen.Bq_generator;;

type t = tree [@@deriving sexp, quickcheck]

let bst_bespoke_limits = 1000

open BQ.Let_syntax

let rec gen ~(lo: int) ~(hi: int)  =
  let%bind sz = size in
  if lo >= hi || sz <= 1 
    then return E
  else
    weighted_union [
      (1., return E);
      (float_of_int sz , (
        let%bind k = int_inclusive ~lo ~hi in
        let%bind v = Nat.quickcheck_generator_parameterized 1000 in
        let%bind left = with_size (gen ~lo:lo ~hi:(k - 1)) ~size_c:(sz / 2) in
        let%bind right = with_size (gen ~lo:(k + 1) ~hi:hi) ~size_c:(sz / 2) in
        return (T (left, k, v, right))  
      ))
    ]

  let quickcheck_generator = gen ~lo:0 ~hi:(1000)