type tree = Leaf | Node of tree * tree

type bst =
  | E
  | T of bst * Nat.t * Nat.t * bst