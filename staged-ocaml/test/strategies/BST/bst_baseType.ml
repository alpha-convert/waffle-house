open Type

type t = Type.tree [@@deriving sexp, quickcheck]
