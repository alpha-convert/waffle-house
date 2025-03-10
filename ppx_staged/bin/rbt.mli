open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Base_quickcheck;;
open Sexplib;;

type color = R | B [@@deriving sexp, quickcheck]

type t =
| E
| T of color * t * int * int * t [@@deriving quickcheck, sexp]

val quickcheck_generator : t Generator.t

val sexp_of_t : t -> Sexp.t