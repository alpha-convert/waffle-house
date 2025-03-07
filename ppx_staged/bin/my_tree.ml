open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Sexplib0;;
open Sexplib0.Sexp_conv;;
open Base;;
open Base_quickcheck;;
open Splittable_random;;

let quickcheck_generator_bounded_int =
  Base_quickcheck.Generator.int_uniform_inclusive 0 100

type bounded_int = int [@@deriving quickcheck, sexp]

type t =
| E
| T of t * bounded_int * bounded_int * t [@@deriving quickcheck, sexp]

let quickcheck_generator = quickcheck_generator

let sexp_of_t = sexp_of_t