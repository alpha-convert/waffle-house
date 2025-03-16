package STLC

enum Typ:
    case TBool
    case TFun(dom : Typ, cod : Typ)


enum Expr:
    case Var(idx : Long)
    case Bool(v : Boolean)
    case Abs(t : Typ, body : Expr)
    case App(fun : Expr, arg : Expr)

// let rec equal x y =
//   match x, y with
//   | TBool, TBool -> true
//   | TFun(x1,x2), TFun(y1,y2) -> equal x1 y1 && equal x2 y2
//   | _ -> false

// // enum Bst:
// //   case E
// //   case Node(left : Bst, key : Long, value : Nat, right : Bst)

// //   override def toString: String = this match
// //     case E => "E"
// //     case Node(left, key, value, right) => 
// //       s"Node($left, $key, $value, $right)
