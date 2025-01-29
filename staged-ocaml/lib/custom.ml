open Core

type custom_list = 
  | Nil
  | Cons of bool * custom_list [@@deriving sexp, quickcheck]