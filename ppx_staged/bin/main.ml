open Stdio
open Base
open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;
(* open Base_quickcheck;; *)
(* open Modules;; *)

module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)

module Tuple = struct 
  type t = bool * int * int [@@deriving wh]
end

let () =
let generator = G_SR.jit (Tuple.quickcheck_generator) in
let () = G_SR.print (Tuple.quickcheck_generator) in
let random = Splittable_random.State.of_int 5 in
let size = 10 in
for _ = 1 to 10 do
  let (b,b',b'') = Base_quickcheck.Generator.generate generator ~size ~random in
  printf "\n\n%s,%s,%s" (Bool.to_string b) (Int.to_string b') (Int.to_string b'')
done