open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;
open Sexplib;;
open Sexplib0.Sexp_conv;;
open Core
open Core_bench;;

module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
module C_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)
module G_BQ = Fast_gen.Bq_generator
(*
let quickcheck_generator_int_new = Base_quickcheck.Generator.int_uniform_inclusive 0 1000

type color = R | B [@@deriving wh, sexp, quickcheck]

type tree = 
  | E 
  | T of color 
       * tree
       * (int [@quickcheck.generator quickcheck_generator_int_new]) 
       * (int [@quickcheck.generator quickcheck_generator_int_new]) 
       * tree
[@@deriving wh, sexp, quickcheck]
*)
(*
let quickcheck_generator_int_new = Base_quickcheck.Generator.int_uniform_inclusive 0 128

type tree =
  | E
  | T of tree * (int [@quickcheck.generator quickcheck_generator_int_new]) * (int [@quickcheck.generator quickcheck_generator_int_new]) * tree
[@@deriving sexp, quickcheck]

type tree_staged =
  | E
  | T of tree_staged * int * int * tree_staged [@@deriving wh]
*)
(*
let quickcheck_generator_int_new = Base_quickcheck.Generator.int_uniform_inclusive Int.min_value Int.max_value

type t = (int [@quickcheck.generator quickcheck_generator_int_new]) * (int [@quickcheck.generator quickcheck_generator_int_new]) [@@deriving wh, quickcheck, sexp]

let () =
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (staged_quickcheck_generator) in
  let () = G_SR.print staged_quickcheck_generator in  
  let random_a = Splittable_random.State.of_int 0 in
  let random_b = Splittable_random.State.of_int 0 in
  let size = 10 in
  for _ = 1 to 10 do
    printf "\n";
    printf "\n";
    let quickc_values = Base_quickcheck.Generator.generate quickcheck_generator ~size ~random:random_a in
    let staged_values = Base_quickcheck.Generator.generate generator ~size ~random:random_b in
    printf "========== quickcheck_generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (sexp_of_t quickc_values));
    printf "========= Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (sexp_of_t staged_values))
  done
*)
(*
type t =
| E
| T of t * int * int * t [@@deriving wh, quickcheck, sexp]
*)
(*
let () =
  let generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (My_list_generator.staged_quickcheck_generator) in
  let () = G_SR.print (My_list_generator.staged_quickcheck_generator) in  
  let random_a = Splittable_random.State.of_int 0 in
  let random_b = Splittable_random.State.of_int 0 in
  let size = 10 in
  for _ = 1 to 10 do
    printf "\n";
    printf "\n";
    let quickc_values = Base_quickcheck.Generator.generate My_list.quickcheck_generator ~size ~random:random_a in
    let staged_values = Base_quickcheck.Generator.generate generator ~size ~random:random_b in
    printf "========== quickcheck_generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_list.sexp_of_t quickc_values));
    printf "========= Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_list.sexp_of_t staged_values))
  done
*)
(*
let () =
  let qc_generator = My_list.quickcheck_generator in
  let st_generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (My_list_generator.staged_quickcheck_generator) in
  Bench.bench
    ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 10000) ())
    [
      Bench.Test.create_indexed ~name:"quickcheck" ~args:[10000] (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:(`Deterministic "a") ~size:n qc_generator
      );
      Bench.Test.create_indexed ~name:"staged" ~args:[10000] (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:(`Deterministic "a")  ~size:n st_generator
      );
    ]
*)
(*
let () =
  let st_generator = G_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] Variant_generator.quickcheck_generator in
  let int_gen = quickcheck_generator_int in
  let bq_generator = My_variant.quickcheck_generator in
  let () = G_SR.print Variant_generator.quickcheck_generator in 
  let random_a = Splittable_random.State.of_int 11 in
  let random_b = Splittable_random.State.of_int 11 in
  let size = 3 in
  for _ = 1 to 10 do 
    printf "\n";
    let st = Base_quickcheck.Generator.generate st_generator ~size ~random:random_a in
    let bq = Base_quickcheck.Generator.generate bq_generator ~size ~random:random_b in
    printf "========== Quickcheck generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (Variant_generator.sexp_of_t bq));
    printf "========== Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (Variant_generator.sexp_of_t st))
  done
*)

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
(*
let () =
  let generator = C_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (My_tree_generator.staged_quickcheck_generator) in
  let () = C_SR.print (My_tree_generator.staged_quickcheck_generator) in  
  let random_a = Splittable_random.State.of_int 0 in
  let random_b = Splittable_random.State.of_int 0 in
  let size = 10 in
  for _ = 1 to 1 do
    printf "\n";
    printf "\n";
    let quickc_values = Base_quickcheck.Generator.generate My_tree.quickcheck_generator ~size ~random:random_a in
    let staged_values = Base_quickcheck.Generator.generate generator ~size ~random:random_b in
    printf "========== quickcheck_generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_tree.sexp_of_t quickc_values));
    printf "========= Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (My_tree.sexp_of_t staged_values))
  done
*)
open Core_unix

let () =
  let generator = C_SR.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/ppx_staged/_build/default/bin/.main.eobjs/byte"] (Rbt_gen.staged_quickcheck_generator) in
  let () = C_SR.print Rbt_gen.staged_quickcheck_generator in
  let random_a = Splittable_random.State.of_int 0 in
  let random_b = Splittable_random.State.of_int 0 in
  let size = 10 in
  for _ = 1 to 1 do
    printf "\n";
    printf "\n";
    let quickc_values = Base_quickcheck.Generator.generate Rbt.quickcheck_generator ~size ~random:random_a in
    let staged_values = Base_quickcheck.Generator.generate generator ~size ~random:random_b in
    printf "========== quickcheck_generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (Rbt.sexp_of_t quickc_values));
    printf "========= Staged generator ==========\n";
    printf "%s\n" (Sexp.to_string_hum (Rbt.sexp_of_t staged_values))
  done
