open Base_quickcheck.Generator
open Let_syntax

type t = bool list

let quickcheck_generator =
  fixed_point (fun r ->
    let%bind n = size in
    if n <= 0 then return []
    else
      let%bind x = bool in
      let%bind xs = with_size ~size:(n-1) r in
      return (x :: xs)
  )