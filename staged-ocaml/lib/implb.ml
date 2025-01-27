open Option

let ( >>= ) = bind
let ( <$> ) f x = match x with None -> None | Some v -> Some (f v)
let return x = Some x

type color = R | B [@@deriving sexp, quickcheck]

type tree = E | T of color *  tree * Core.Bool.t * Core.Bool.t * tree
[@@deriving sexp, quickcheck]

type key = int
type value = int
type rbt = tree [@@deriving sexp, quickcheck]
