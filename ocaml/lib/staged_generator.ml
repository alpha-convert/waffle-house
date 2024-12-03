open Core;;

open Codegen.Let_syntax

type 'a t = RandGen of (size:(int Code.t) -> random:(Splittable_random.State.t Code.t) -> 'a Codegen.t)

let return x = RandGen (fun ~size:_ ~random:_ -> Codegen.return x)
