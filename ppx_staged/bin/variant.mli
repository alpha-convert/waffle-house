open Stdio
open Base
open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;

type t = 
| MyInt of int
| MyFloat of (float * bool) * int
| MyPair of int * float [@@deriving sexp]