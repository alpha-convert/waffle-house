open Stdio
open Base
open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;
module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
open Sexplib;;
open Sexplib0.Sexp_conv;;

let () =
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (My_tree_generator.quickcheck_generator) in
  let () = G_SR.print (My_tree_generator.quickcheck_generator) in  
  let random = Splittable_random.State.of_int 1000 in
  let size = 1000 in
  for _ = 1 to 1000 do
    let value = Base_quickcheck.Generator.generate generator ~size ~random in
    printf "%s\n" (Sexp.to_string_hum (My_tree_generator.sexp_of_t value))
  done