open QCheck
open Crowbar
open Util.Runner
open Util.Io
open RBT.Impl
open RBT.Test
open RBT.QcheckType
open RBT.BaseTypeStaged
open RBT.QcheckBespoke
open RBT.CrowbarType
open RBT.CrowbarBespoke
open RBT.BaseType
open RBT.BaseBespoke
(*
open Core
open Core_bench;;
 Generate and print trees for a given size and seed
let compare_and_print_trees ~size ~seed =
  let random_state = Splittable_random.State.of_int seed in
  let list_base_type =
    Base_quickcheck.Generator.generate
      BaseType.quickcheck_generator
      ~size
      ~random:random_state
  in
  let random_state = Splittable_random.State.of_int seed in
  let list_base_type_staged =
    Base_quickcheck.Generator.generate
      BaseTypeStaged.quickcheck_generator
      ~size
      ~random:random_state
  in
  printf "Seed: %d, Size: %d\n" seed size;
  printf "BaseType:\n%s\n" (Sexp.to_string_hum ([%sexp_of: rbt] list_base_type));
  printf "BaseTypeStaged:\n%s\n\n" (Sexp.to_string_hum ([%sexp_of: rbt] list_base_type_staged))
*)
(* RUNNER COMMAND:
   dune exec RBT -- qcheck prop_DeleteValid bespoke out.txt
   dune exec RBT -- qcheck prop_DeleteValid type out.txt
   dune exec RBT -- crowbar prop_DeleteValid bespoke out.txt
   dune exec RBT -- crowbar prop_DeleteValid type out.txt
   dune exec RBT -- afl prop_DeleteValid bespoke out.txt
   dune exec RBT -- afl prop_DeleteValid type out.txt
   dune exec RBT -- base prop_DeleteValid type out
*)

let properties : (string * rbt property) list =
  [
    (* ("prop_InsertValid", test_prop_InsertValid);
    (* ("prop_DeleteValid", test_prop_DeleteValid); *)
    ("prop_InsertPost", test_prop_InsertPost);
    ("prop_DeletePost", test_prop_DeletePost);
    ("prop_InsertModel", test_prop_InsertModel);
    ("prop_DeleteModel", test_prop_DeleteModel);
    ("prop_InsertInsert", test_prop_InsertInsert);
    ("prop_InsertDelete", test_prop_InsertDelete);
    ("prop_DeleteInsert", test_prop_DeleteInsert);
    *)
    ("prop_DeleteDelete", test_prop_DeleteDelete);
  ]

let qstrategies : (string * rbt arbitrary) list =
  [ ("type", qcheck_type); ("bespoke", qcheck_bespoke) ]

let cstrategies : (string * rbt gen) list =
  [ ("type", crowbar_type); ("bespoke", crowbar_bespoke) ]

let bstrategies : (string * rbt basegen) list =
  [ ("type", (module BaseType)); ("bespoke", (module BaseBespoke)); ("type_staged", (module BaseTypeStaged))]

let () =
  main properties qstrategies cstrategies bstrategies
