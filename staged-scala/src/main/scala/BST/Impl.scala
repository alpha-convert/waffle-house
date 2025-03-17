package BST

import Nat.*

enum Bst:
  case E
  case Node(left : Bst, key : Long, value : Nat, right : Bst)

  override def toString: String = this match
    case E => "E"
    case Node(left, key, value, right) => 
      s"Node($left, $key, $value, $right)"
