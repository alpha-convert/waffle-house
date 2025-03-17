package RBT

import Nat.*

enum Color:
  case Red
  case Black

enum Rbt:
  case E
  case Node(color : Color, left : Rbt, key : Long, value : Nat, right : Rbt)
