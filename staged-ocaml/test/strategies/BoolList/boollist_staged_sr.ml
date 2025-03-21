module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
open G
open Let_syntax

let staged_generator =
  recursive (G.C.lift ()) (fun r u ->
    let%bind n = size in
    let%bind leqz = split_bool .< .~n <= 0 >. in
    if leqz then return (.<[]>.)
    else
      let%bind x = bool in
      let%bind xs = with_size ~size_c:(.<.~n - 1>.) (recurse r u) in
      return (.< (.~x :: .~xs) >.)
  )

let quickcheck_generator = 
  G.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte"] staged_generator
  