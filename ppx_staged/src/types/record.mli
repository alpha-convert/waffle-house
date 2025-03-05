open Base
open Base_quickcheck

type t = {
  flag: bool;
  first: int;
  second: int;
} [@@deriving sexp, quickcheck]

val quickcheck_generator : t Base_quickcheck.Generator.t
