open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Sexplib0;;
open Sexplib0.Sexp_conv;;

type t =
| Leaf of int
| Node of int * t * int [@@deriving sexp]
