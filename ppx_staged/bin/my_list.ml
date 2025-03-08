open Stdio
open Base
open Ppx_staged
open Fast_gen;;
open Ppx_staged_expander;;
open Base_quickcheck;;

type t =
| Empty [@quickcheck.weight 1.]
| Cons of bool * t [@quickcheck.weight 10000.] [@@deriving quickcheck, sexp]