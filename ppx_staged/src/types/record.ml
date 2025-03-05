open Base
open Base_quickcheck

type t = {
  flag: bool;
  first: int;
  second: int;
} [@@deriving sexp, quickcheck]
