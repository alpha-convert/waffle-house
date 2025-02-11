open Base

module Typ = struct
  type t = TBool | TFun of t * t [@@deriving eq, sexp]
end

module Expr = struct
  type t = | Var of Int.t | Bool of Bool.t | Abs of Typ.t * t | App of t * t [@@deriving eq, sexp]
end

module Ctx = struct
  type t = Typ.t list
end

