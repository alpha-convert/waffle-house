open Stlc_impl
open Expr
open Typ
open Base

module G = Bq_generator
open G
open Let_syntax

let genTyp : Typ.t G.t =
  recursive () @@ fun go _ ->
    let%bind n = size in
    if n <= 1 then return TBool
    else union [
      return TBool;
      let%bind t1 = with_size ~size_c:(n/2) (recurse go ()) in
      let%bind t2 = with_size ~size_c:(n/2) (recurse go ()) in
      return (TFun (t1,t2))
    ]

let genVar g t : Expr.t option G.t =
  let vars = List.filter_mapi ~f:(fun i t' -> if Typ.equal t t' then Some (Some (Expr.Var i)) else None) g in
  match vars with
  | [] -> return None
  | _ -> of_list vars

let genConst t : Expr.t G.t =
  recursive t @@ fun go t ->
    match t with
    | TBool -> map ~f:(fun b -> Bool b) bool
    | TFun(t1,t2) -> map ~f:(fun e -> Abs(t1,e)) (recurse go t2)

let genExactExpr n g t = recursive (n,g,t) @@ fun go (n,g,t) ->
  let%bind me = genVar g t in
  match me with
  | Some e -> return e
  | None -> if Int.equal n 0 then genConst t else
            match t with
            | TFun (t1,t2) -> map ~f:(fun e -> Abs(t1,e)) (recurse go (n - 1,t1 :: g,t2))
            | _ -> genTyp >>= fun t' ->
                   let r1 = recurse go (n/2,g,TFun(t',t)) in
                   let r2 = recurse go (n/2,g,t') in
                   map2 r1 r2 ~f:(fun e1 e2 -> App(e1,e2))
                   
let genExpr =
  let%bind n = size in
  let%bind t = genTyp in
  genExactExpr n [] t