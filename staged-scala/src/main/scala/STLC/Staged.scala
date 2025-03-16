package STLC

package STLC

import stagedgen.StGen
import stagedgen.Splittable
import stagedgen.Splittable.given
import stagedgen.SplittableCps.given
import scala.quoted.*

import STLC.* 

object Staged {
    def genTBool(using Quotes) = StGen.pure('{Typ.TBool})

    def genTyp(using Quotes) : StGen[Expr[Typ]] =
        StGen.recursive[Typ,Unit] (
            rh => _ =>
                StGen.size.flatMap (sz =>
                    '{$sz <= 1}.split.flatMap(b =>
                        if(b) {
                            genTBool
                        } else {
                            StGen.frequency (
                                '{1} -> genTBool,
                                sz -> (for {
                                    t1 <- StGen.resize('{$sz/2}, rh('{()}))
                                    t2 <- StGen.resize('{$sz/2}, rh('{()}))
                                } yield '{Typ.TFun($t1,$t2)})
                            )
                        }
                        
                    )
                )
        )('{()})

}

// let genVar g t : expr option G.t =
//   let vars = List.filter_mapi ~f:(fun i t' -> if Type_defn.equal t t' then Some (Some (Var i)) else None) g in
//   match vars with
//   | [] -> return None
//   | _ -> of_list vars

// let genConst t : expr G.t =
//   recursive t @@ fun go t ->
//     match t with
//     | TBool -> map ~f:(fun b -> Bool b) bool
//     | TFun(t1,t2) -> map ~f:(fun e -> Abs(t1,e)) (recurse go t2)

// let genExactExpr n g t = recursive (n,g,t) @@ fun go (n,g,t) ->
//   let%bind me = genVar g t in
//   match me with
//   | Some e -> return e
//   | None -> if n <= 1 then genConst t else
//             match t with
//             | TFun (t1,t2) -> map ~f:(fun e -> Abs(t1,e)) (recurse go (n - 1,t1 :: g,t2))
//             | _ -> let%bind t' = genTyp in
//                    let%bind e1 = recurse go (n/2,g,TFun(t',t)) in
//                    let%bind e2 = recurse go (n/2,g,t') in
//                    return (App (e1,e2))

// let genExpr =
//   let%bind n = size in
//   let%bind t = genTyp in
//   genExactExpr n [] t

// let quickcheck_generator = genExpr