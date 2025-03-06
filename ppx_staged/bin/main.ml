open Stdio
open Base
open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;
module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
(*
type t =
| Empty
| Cons of int * t [@@deriving wh]
*)

let () =
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (My_list_generator.quickcheck_generator_my_list) in
  let () = G_SR.print (My_list_generator.quickcheck_generator_my_list) in
  let random = Splittable_random.State.of_int 5 in
  let size = 10 in
  for _ = 1 to 10 do
    My_list_generator.show (Base_quickcheck.Generator.generate generator ~size ~random)
    (* Stdio.print_endline (Sexp.to_string_hum (Variant.sexp_of_variant value))*)
  done

(*
module Tuple = struct 
  type t = bool * int * int [@@deriving wh]
end

let () =
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (Variant_generator.quickcheck_generator_variant) in
  let () = G_SR.print (Variant_generator.quickcheck_generator_variant) in
  let random = Splittable_random.State.of_int 5 in
  let size = 10 in
  for _ = 1 to 10 do
    Variant_generator.show (Base_quickcheck.Generator.generate generator ~size ~random)
    (* Stdio.print_endline (Sexp.to_string_hum (Variant.sexp_of_variant value))*)
  done
*)