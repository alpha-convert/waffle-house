open Spec
open Type_defn
open Util
open Runner
open Crowbar

let ( << ) f g x = f (g x)

let test_prop_SinglePreserve : expr property =
  {
    name = "test_prop_SinglePreserve";
    b = (fun ~generator ~name ~seed -> bbuild generator (bmake << prop_SinglePreserve) ~seed:(Some seed) ~name);
  }

let test_prop_MultiPreserve : expr property =
  {
    name = "test_prop_MultiPreserve";
    b = (fun ~generator ~name ~seed -> bbuild generator (bmake << prop_MultiPreserve) ~seed:(Some seed) ~name);
  }
