open Stdio
open Fast_gen;;
open Ppx_staged_expander;;

type t =
| Leaf of int
| Node of int * t * int [@@deriving sexp]
