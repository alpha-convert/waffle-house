open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Base_quickcheck;;
open Sexplib;;

type t =
| E
| T of t * int * int * t [@@deriving quickcheck, sexp]

val quickcheck_generator : t Generator.t

val sexp_of_t : t -> Sexp.t