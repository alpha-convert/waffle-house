(*
open STLC.QcheckType
open STLC.QcheckBespoke
open STLC.CrowbarType
open STLC.CrowbarBespoke
open STLC.Impl
open STLC.Test
open Util.Io
open Util.Runner
open QCheck
*)

open STLC.BaseType
open STLC.BaseBespoke
open STLC.BaseBespokeStaged
open Core
open Core_bench;;

(* RUNNER COMMAND:
   dune exec STLC -- qcheck prop_SinglePreserve bespoke out
   dune exec STLC -- qcheck prop_SinglePreserve type out
   dune exec STLC -- crowbar prop_SinglePreserve bespoke out
   dune exec STLC -- crowbar prop_SinglePreserve type out
   dune exec STLC -- afl prop_SinglePreserve bespoke out
   dune exec STLC -- afl prop_SinglePreserve type out
   dune exec STLC -- base prop_SinglePreserve bespoke out
   dune exec STLC -- base prop_SinglePreserve type out

let properties : (string * expr property) list =
  [
    ("prop_SinglePreserve", test_prop_SinglePreserve);
    ("prop_MultiPreserve", test_prop_MultiPreserve);
  ]

let qstrategies : (string * expr arbitrary) list =
  [ ("type", qcheck_type); ("bespoke", qcheck_bespoke) ]

let cstrategies : (string * expr Crowbar.gen) list =
  [ ("type", crowbar_type); ("bespoke", crowbar_bespoke) ]

let bstrategies : (string * expr basegen) list =
  [ ("type", (module BaseType)); ("bespoke", (module BaseBespoke)) ]

let () = main properties qstrategies cstrategies bstrategies
*)

let () =
  let sizes = [10; 50; 100; 1000; 10000] in
  Bench.bench
    ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 1000) ())
    [
      Bench.Test.create_indexed ~name:"gen_type" ~args:sizes (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n BaseType.quickcheck_generator
      );
      Bench.Test.create_indexed ~name:"gen_bespoke" ~args:sizes (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n BaseBespoke.quickcheck_generator
      );
      Bench.Test.create_indexed ~name:"gen_type_staged" ~args:sizes (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n BaseBespokeStaged.quickcheck_generator
      );
    ]