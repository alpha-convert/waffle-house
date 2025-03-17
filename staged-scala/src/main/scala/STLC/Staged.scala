package STLC

package STLC

import stagedgen.StGen
import stagedgen.Splittable
import stagedgen.Splittable.given
import stagedgen.SplittableCps.given
import STLC.* 
import scala.quoted.*


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


    def genVar(g : Expr[List[Typ]],t : Expr[Typ])(using Quotes) : StGen[Expr[Option[Term]]] = {
        val vars : Expr[List[Option[Term]]] = '{$g.zipWithIndex.flatMap { (t2, i) => 
            if ($t == t2) { Some(Some(Term.Var(i))) } else { None }
        }}
        vars.split.flatMap(vs =>
            vs match {
                case Left(_) => StGen.pure('{None})
                case Right(_) => StGen.oneOfDyn(vars)
            }
        )
    }

    def genConst(t : Expr[Typ])(using Quotes) : StGen[Expr[Term]] = {
        StGen.recursive[Term,Typ](rh => tc =>
            tc.split.flatMap(t =>
                t match {
                    case _ => StGen.oneOf('{true},'{false}).map(b => '{Term.Bool($b)})
                    case (t1,t2) => rh(t2).map(e => '{Term.Abs($t1,$e)})
                }
            )
        )(t)
        
    }

    def genExactTerm(g : Expr[List[Typ]], t : Expr[Typ])(using Quotes) : StGen[Expr[Term]] = {
        StGen.recursive[Term,(List[Typ],Typ)](rh => gt => 
            gt.split.flatMap((g,t) =>
                genVar(g,t).flatMap(mec =>
                    mec.split.flatMap(me =>
                        me match {
                            case Some(e) => StGen.pure(e)
                            case None => StGen.size.flatMap(n =>
                                '{$n <= 1}.split.flatMap(leq =>
                                    if(leq){
                                        genConst(t)
                                    } else {
                                       t.split.flatMap(tf =>
                                            tf match {
                                                case (t1,t2) => StGen.resize('{$n-1},rh('{($t1::$g,$t2)})).map(e => '{Term.Abs($t1,$e)})
                                                case _ => (for {
                                                    t2 <- genTyp
                                                    e1 <- StGen.resize('{$n/2},rh('{($g,Typ.TFun($t2,$t))}))
                                                    e2 <- StGen.resize('{$n/2},rh('{($g,$t2)}))
                                                } yield '{Term.App($e1,$e2)}
                                                )
                                            }
                                       )
                                    }
                                )
                            )
                        }

                    )
                )
            )

        )('{($g,$t)})
    }

}
