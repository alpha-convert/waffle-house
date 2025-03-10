open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Sexplib0;;
open Sexplib0.Sexp_conv;;
open Base;;
open Base_quickcheck;;
open Splittable_random;;

let quickcheck_generator_int_new = Base_quickcheck.Generator.int_uniform_inclusive 0 1000

type t =
| E
| T of t * (int [@quickcheck.generator quickcheck_generator_int_new]) * (int [@quickcheck.generator quickcheck_generator_int_new]) * t [@@deriving quickcheck, sexp]

let quickcheck_generator = quickcheck_generator

let sexp_of_t = sexp_of_t