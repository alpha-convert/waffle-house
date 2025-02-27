open Codelib
open Fast_gen
open Stlc_impl
open Expr
open Base
open Typ

module M : Fast_gen.Splittable.S = struct
    type nonrec t = Expr.t
    type nonrec f = VarF of Int.t code | BoolF of Bool.t code | AbsF of (Typ.t code) * (Expr.t code) | AppF of (Expr.t code) * (Expr.t code)

    let split (e : t code) : f Codecps.t = {
      code_gen = fun k -> .<
        match .~e with
        | Var x -> .~(k (VarF .<x>.))
        | Bool b -> .~(k (BoolF .<b>.))
        | Abs (t,e') -> .~(k (AbsF (.<t>.,.<e'>.)))
        | App (e,e') -> .~(k (AppF (.<e>.,.<e'>.)))
      >.
    }
  end

module MT : Fast_gen.Splittable.S with type t = Typ.t and type f = [`TBool | `TFun of (Typ.t code) * (Typ.t code)]
= struct
    type nonrec t = Typ.t
    type nonrec f = [`TBool | `TFun of (Typ.t code) * (Typ.t code)]

    let split (e : t code) : f Codecps.t = {
      code_gen = fun k -> .<
        match .~e with
        | TBool -> .~(k `TBool)
        | TFun (t,t') -> .~(k (`TFun (.<t>.,.<t'>.)))
      >.
    }
  end

module Gen = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
open Gen
open Let_syntax
module GS = Gen.MakeSplit(M)
module GTS = Gen.MakeSplit(MT)
let split_expr = GS.split
let split_typ = GTS.split

let genTyp : Typ.t code Gen.t =
  recursive .<()>. @@ fun go u ->
    let%bind n = size in
    let%bind b = split_bool .< .~n <= 1 >. in
    if b then return .<TBool>.
    else
      weighted_union [
        .<1.0>., return .<TBool>.;
        .<Int.to_float .~n>.,
          let%bind t1 = with_size ~size_c:.<.~n / 2>. (recurse go u) in
          let%bind t2 = with_size ~size_c:.<.~n / 2>. (recurse go u) in
          return .<TFun(.~t1,.~t2)>.
      ]

let genConst t : Expr.t code Gen.t =
    recursive t @@ fun go t ->
      let%bind t = split_typ t in
      match t with
      | `TBool -> map ~f:(fun b -> .<Bool .~b>.) bool
      | `TFun(t1,t2) -> map ~f:(fun e -> .<Abs(.~t1,.~e)>.) (recurse go t2)

let genVar g t : Expr.t option code Gen.t =
  let%bind vars = return .<List.filter_mapi ~f:(fun i t' -> if Typ.equal .~t t' then Some (Some (Expr.Var i)) else None) .~g>. in
  let%bind vars_s = split_list vars in
  match vars_s with
  | `Nil -> return .<None>.
  | `Cons _ -> of_list_dyn vars

let genExactExpr n g t = recursive .<(.~n,.~g,.~t)>. @@ fun go ngt ->
  let%bind (n,g,t) = split_triple ngt in
  let%bind me = (genVar g t) >>= split_option in
  match me with
  | `Some e -> return e
  | `None ->
      let%bind b = split_bool .<.~ n <= 1>. in
      if b then genConst t else
      let%bind ts = split_typ t in
      match ts with
      | `TFun (t1,t2) -> map ~f:(fun e -> .<Abs(.~t1,.~e)>.) (recurse go .<(.~n - 1,.~t1 :: .~g,.~t2)>.)
      | _ ->
          let%bind t' = genTyp in
          let%bind e1 = recurse go .<(.~n/2,.~g,TFun(.~t',.~t))>. in
          let%bind e2 = recurse go .<(.~n/2,.~g,.~t')>. in
          return .<App(.~e1,.~e2)>.

let genExpr =
  let%bind n = size in
  let%bind t = genTyp in
  genExactExpr n .<[]>. t