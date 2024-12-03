open Core;;
open Code;;

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