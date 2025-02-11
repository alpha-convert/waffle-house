(* open Stlc_impl
open Expr
open Typ
open Base

module G = Fast_gen.Staged_generator
let (>>=) = G.(>>=)


let genTyp : Typ.t G.t =
  let go n = G.recursive n @@ fun go n ->
    G.split_bool .< n = 0 >. >>= fun b ->
    if b then
      G.return .< TBool >.
    else G.union [
      G.return TBool;
      G.map2 ~f:(fun t1 t2 -> TFun(t1,t2)) (G.recurse go (n / 2)) (G.recurse go (n / 2))
    ]
  in
  G.bind ~f:go G.size

let genVar g t : Expr.t option G.t =
  let vars = List.filter_mapi ~f:(fun i t' -> if Typ.equal t t' then Some (G.return (Some (Expr.Var i))) else None) g in
  match vars with
  | [] -> G.return None
  | _ -> G.union vars

let genConst t : Expr.t G.t =
  G.recursive t @@ fun go t ->
    match t with
    | TBool -> G.map ~f:(fun b -> Bool b) G.bool
    | TFun(t1,t2) -> G.map ~f:(fun e -> Abs(t1,e)) (G.recurse go t2)

let genExactExpr n g t = G.recursive (n,g,t) @@ fun go (n,g,t) ->
  genVar g t >>= fun me ->
  match me with
  | Some e -> G.return e
  | None -> if Int.equal n 0 then genConst t else
            match t with
            | TFun (t1,t2) -> G.map ~f:(fun e -> Abs(t1,e)) (G.recurse go (n - 1,t1 :: g,t2))
            | _ -> genTyp >>= fun t' ->
                   let r1 = G.recurse go (n/2,g,TFun(t',t)) in
                   let r2 = G.recurse go (n/2,g,t') in
                   G.map2 r1 r2 ~f:(fun e1 e2 -> App(e1,e2))
                   
let genExpr =
  G.size >>= fun n ->
  genTyp >>= fun t ->
  genExactExpr n [] t *)