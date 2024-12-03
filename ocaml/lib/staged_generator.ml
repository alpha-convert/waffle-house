open Core;;

open Codegen.Let_syntax

type 'a t = RandGen of (size_c:(int Code.t) -> random_c:(Splittable_random.State.t Code.t) -> 'a Codegen.t)

let return x = RandGen (fun ~size_c:_ ~random_c:_ -> Codegen.return x)
let bind (RandGen r) ~f = RandGen (fun ~size_c ~random_c ->
  let%bind a = r ~size_c ~random_c in
  let (RandGen r') = f a in
  r' ~size_c ~random_c
)

module For_monad = Monad.Make (struct
    type nonrec 'a t = 'a t

    let return = return
    let bind = bind
    let map = `Define_using_bind
  end)

let join = For_monad.join


module Monad_infix = For_monad.Monad_infix
include Monad_infix
module Let_syntax = For_monad.Let_syntax

let to_qc (sg : ('a Code.t) t) : ('a Base_quickcheck.Generator.t) Code.t =
  let (RandGen f) = sg in
  [%code
    Base_quickcheck.Generator.create (fun ~size ~random ->
      [%e Codegen.code_generate (f ~size_c:[%code size] ~random_c:[%code random]) ]
    )
  ]

exception Unimplemented

let weighted_union = raise Unimplemented
let with_size = raise Unimplemented
let size = raise Unimplemented