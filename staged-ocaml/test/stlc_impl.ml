open Base

module Typ = struct
  type t = TBool | TFun of t * t [@@deriving sexp, show]

  let rec equal x y =
    match x, y with
    | TBool, TBool -> true
    | TFun(x1,x2), TFun(y1,y2) -> equal x1 y1 && equal x2 y2
    | _ -> false
end

module Expr = struct
  type t = | Var of Int.t | Bool of Bool.t | Abs of Typ.t * t | App of t * t [@@deriving eq, sexp, show]

end

module Ctx = struct
  type t = Typ.t list
end

