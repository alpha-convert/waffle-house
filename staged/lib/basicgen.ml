open Core;;
open Tree;;

open Core.Quickcheck.Generator;;
open Core.Quickcheck.Let_syntax;;

let gen =
  fixed_point (
    fun gt ->
      let%bind n = size in
      if n <= 1 then return Leaf else
      weighted_union [
        (1.0,return Leaf);
        (Int.to_float n,
          let%bind l = with_size ~size:(n / 2) gt in
          let%bind r = with_size ~size:(n / 2) gt in
          return (Node (l,r))
        )
      ]
  )