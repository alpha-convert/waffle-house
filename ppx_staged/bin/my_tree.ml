open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Sexplib0;;
open Sexplib0.Sexp_conv;;
open Base;;
open Base_quickcheck;;
open Splittable_random;;

type t =
| E
| T of t * int * int * t [@@deriving quickcheck, sexp]

let quickcheck_generator = quickcheck_generator

let sexp_of_t = sexp_of_t