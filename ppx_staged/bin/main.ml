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

let quickcheck_generator_int =
  Base_quickcheck.Generator.create (fun ~size:_ ~random ->
    Splittable_random.int random ~lo:0 ~hi:10)

type t = int [@@deriving wh, quickcheck, sexp]

let () =
  let st_generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] staged_quickcheck_generator in
  let int_gen = quickcheck_generator_int in
  let bq_generator = quickcheck_generator in
  let () = G_SR.print staged_quickcheck_generator in 
  let random = Splittable_random.State.of_int 11 in
  let size = 3 in
  for _ = 1 to 10 do 
    printf "\n";
    let st = Base_quickcheck.Generator.generate st_generator ~size ~random in
    let bq = Base_quickcheck.Generator.generate bq_generator ~size ~random in
    printf "========== Quickcheck generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (sexp_of_t bq));
    printf "========== Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (sexp_of_t st))
  done
(*
let () =
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (My_tree_generator.staged_quickcheck_generator) in
  let () = G_SR.print (My_tree_generator.staged_quickcheck_generator) in  
  let random = Splittable_random.State.of_int 11 in
  let size = 3 in
  for _ = 1 to 2 do
    printf "\n";
    let value1 = Base_quickcheck.Generator.generate My_tree.quickcheck_generator ~size ~random in
    let value2 = Base_quickcheck.Generator.generate generator ~size ~random in
    printf "========== My_tree.quickcheck_generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_tree_generator.sexp_of_t value1));
    printf "========== Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_tree_generator.sexp_of_t value2))
  done
*)