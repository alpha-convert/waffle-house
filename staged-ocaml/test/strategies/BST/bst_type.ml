open Core;;
(* open Ppx_staged;; *)
open Nat;;

type tree =
| E
| T of tree * (Nat.t [@wh.randomness "sr_t"] ) * (Nat.t [@wh.randomness "sr_t"]) * tree [@@deriving quickcheck, sexp]

let rec insert_correct (t : tree) (k, v) =
  match t with
  | E -> T (E, k, v, E)
  | T (l, k', v', r) ->
      if k < k' then T (insert_correct l (k, v), k', v', r)
      else if k' < k then T (l, k', v', insert_correct r (k, v))
      else T (l, k', v, r)

let repeat_insert (lst : (Nat.t * Nat.t) list) : tree =
  List.fold_left ~f:insert_correct ~init:E lst

let geq x y =
  if x >= y then true else false