
open QCheck
open Crowbar
open Util.Runner
open RBT.Test
open RBT.QcheckType
open RBT.QcheckBespoke
open RBT.CrowbarType
open RBT.CrowbarBespoke
open RBT.BaseBespoke
open Util.Io


open RBT.BaseType
open RBT.BaseTypeStaged
open RBT.Impl
(*
open Core

(* Define a function to compare two rbts *)
let compare_trees rbt1 rbt2 =
  (* Replace this with a proper equality function for rbt *)
  equal_rbt rbt1 rbt2

(* Compare and print trees with a comparison result *)
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
  printf "BaseTypeStaged:\n%s\n" (Sexp.to_string_hum ([%sexp_of: rbt] list_base_type_staged));

  (* Compare the trees and print the result *)
  if compare_trees list_base_type list_base_type_staged then
    printf "The two trees are equal.\n\n"
  else
    printf "The two trees are NOT equal.\n\n"

(* Main function *)
let () =
  let sizes = [10] in (* Test sizes *)
  let seeds = [42; 123; 67; 144; 7; 13; 234248; 1410421; 23923; 34740; 33; 78; 99; 0; 432; 1; 2; 3; 4; 5; 6; -148237557032047; 834234102] in (* Deterministic seeds *)

  List.iter sizes ~f:(fun size ->
      List.iter seeds ~f:(fun seed ->
          compare_and_print_trees ~size ~seed))
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
