(*
open Fast_gen;;
open Ppx_staged;;
*)
open Core;;

type typ = TBool | TFun of typ * typ [@@deriving sexp, quickcheck]

type expr =
  | Var of int
  | Bool of bool
  | Abs of typ * expr
  | App of expr * expr
[@@deriving sexp, quickcheck]

type ctx = typ list

let rec equal x y =
  match x, y with
  | TBool, TBool -> true
  | TFun(x1,x2), TFun(y1,y2) -> equal x1 y1 && equal x2 y2
  | _ -> false