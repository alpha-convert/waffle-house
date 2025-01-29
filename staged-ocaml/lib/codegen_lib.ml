open Core;;
open Ppxlib;;
open Ast_builder.Default;;

let gensym prefix ~loc =
  let sym = gen_symbol ~prefix:("_" ^ prefix) () in
  pvar ~loc sym, evar ~loc sym
;;

type 'a t = {code_gen : (('a -> Ppxlib.expression) -> Ppxlib.expression)}

let run_code_gen {code_gen=f} k = f k

let code_generate : (Ppxlib.expression) t -> Ppxlib.expression =
  fun g -> g.code_gen (fun x -> x)

let return x = { code_gen = fun k -> k x}

let bind ({code_gen = inC } : 'a t) ~(f : 'a -> 'b t) : 'b t = 
  { code_gen = fun k -> inC (fun a -> run_code_gen (f a) k) }

module For_monad = Monad.Make (struct
  type nonrec 'a t = 'a t
  let return = return
  let bind = bind
  let map = `Define_using_bind
end)

module Monad_infix = For_monad.Monad_infix
include Monad_infix
module Let_syntax = For_monad.Let_syntax

let gen_let ~loc (cx : Ppxlib.expression) : Ppxlib.expression t =
  { code_gen = fun k ->
      let pattern, expr = gensym "x" ~loc in
      [%expr let [%p pattern] = [%e cx] in [%e k expr]]
  }

let gen_if ~loc (cb: Ppxlib.expression) ~(tt: 'a t) ~(ff: 'a t) : 'a t =
  {
    code_gen = fun k -> 
      let pattern, _ = gensym "b" ~loc in
      [%expr
      let [%p pattern] = [%e cb] in
      if b then [%e run_code_gen tt k] else [%e run_code_gen ff k ]
    ]
  }

(*
let gen_let (cx: 'a Cod.t) : 'a Cod.t t = 
  {code_gen = fun k ->
    let gensym "x" 
  }
*)

(*
type 'a t = 'a Ppx_stage.code

let gen_let (cx : 'a Code.t) : 'a Code.t t =
  {code_gen = fun k ->
    [%code 
      let x = [%e cx] in [%e k [%code x]]
    ]
  }

let gen_if (cb : bool Code.t) ~(tt : 'a t) ~(ff : 'a t) : 'a t = 
  {
    code_gen = fun k -> [%code
      let b = [%e cb] in
      if b then [%e run_code_gen tt k] else [%e run_code_gen ff k ]
    ]
  }
*)