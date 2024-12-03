open Core;;
open Code;;

(* This is stolen from andras kovacs *)
type 'a t = {code_gen : 'z. (('a -> 'z Code.t) -> 'z Code.t)}

let run_code_gen {code_gen=f} k = f k

let code_generate : ('a Code.t) t -> 'a Code.t =
  fun g -> g.code_gen (fun x -> x)


let return x = { code_gen = fun k -> k x}
let bind ({code_gen = inC } : 'a t) ~(f : 'a -> 'b t) : 'b t = { code_gen = fun k -> inC (fun a -> run_code_gen (f a) k) }

module For_monad = Monad.Make (struct
    type nonrec 'a t = 'a t

    let return = return
    let bind = bind
    let map = `Define_using_bind
  end)

module Monad_infix = For_monad.Monad_infix
include Monad_infix
module Let_syntax = For_monad.Let_syntax

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