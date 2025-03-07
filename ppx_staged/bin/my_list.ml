open Stdio
open Base
open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;
open Base_quickcheck;;

type t =
| Empty
| Cons of bool * t [@@deriving quickcheck, sexp]