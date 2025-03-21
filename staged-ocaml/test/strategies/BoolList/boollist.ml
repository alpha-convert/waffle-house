open Fast_gen.Bq_generator
open Let_syntax

type t = bool list

let quickcheck_generator =
  recursive () (fun r u ->
    let%bind n = size in
    if n <= 0 then return []
    else
      let%bind x = bool in
      let%bind xs = with_size ~size_c:(n-1) (recurse r u) in
      return (x :: xs)
  )