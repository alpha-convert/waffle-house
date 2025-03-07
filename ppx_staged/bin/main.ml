open Stdio
open Base
open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;
module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
module G_BQ = Fast_gen.Bq_generator
open Sexplib;;
open Sexplib0.Sexp_conv;;
open Int;;
open Base_quickcheck;;

(*
let () =
  let st_generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] staged_quickcheck_generator in
  let int_gen = quickcheck_generator_int in
  let bq_generator = quickcheck_generator in
  let () = G_SR.print staged_quickcheck_generator in 
  let random_a = Splittable_random.State.of_int 11 in
  let random_b = Splittable_random.State.of_int 11 in
  let size = 3 in
  for _ = 1 to 10 do 
    printf "\n";
    let st = Base_quickcheck.Generator.generate st_generator ~size ~random:random_a in
    let bq = Base_quickcheck.Generator.generate bq_generator ~size ~random:random_b in
    printf "========== Quickcheck generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (sexp_of_t bq));
    printf "========== Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (sexp_of_t st))
  done
*)

type t =
| E
| T of t * int * int * t [@@deriving wh, sexp]


let () =
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (My_tree_generator.staged_quickcheck_generator) in
  let () = G_SR.print (My_tree_generator.staged_quickcheck_generator) in  
  let random_a = Splittable_random.State.of_int 0 in
  let random_b = Splittable_random.State.of_int 0 in
  let size = 10 in
  for _ = 1 to 10 do
    printf "\n";
    printf "\n";
    let quickc_values = Base_quickcheck.Generator.generate My_tree.quickcheck_generator ~size ~random:random_a in
    let staged_values = Base_quickcheck.Generator.generate generator ~size ~random:random_b in
    printf "========== quickcheck_generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_tree_generator.sexp_of_t quickc_values));
    printf "========== Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_tree_generator.sexp_of_t staged_values))
  done