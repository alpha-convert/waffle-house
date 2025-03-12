type tree =
| E
| T of tree * (Nat.t) * (Nat.t) * tree [@@deriving quickcheck, sexp, eq, show]
