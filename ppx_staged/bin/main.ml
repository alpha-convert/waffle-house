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
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (Variant_generator.quickcheck_generator_variant) in
  let () = G_SR.print (Variant_generator.quickcheck_generator_variant) in
  let random = Splittable_random.State.of_int 5 in
  let size = 10 in
  for _ = 1 to 10 do
    Variant.show (Base_quickcheck.Generator.generate generator ~size ~random)
    (* Stdio.print_endline (Sexp.to_string_hum (Variant.sexp_of_variant value))*)
  done