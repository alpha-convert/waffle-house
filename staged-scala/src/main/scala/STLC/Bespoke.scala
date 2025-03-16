package STLC
import org.scalacheck.Gen
import org.scalacheck.Arbitrary

import STLC.*

object Bespoke {
    def genTyp() : Gen[Typ] =
        Gen.size.flatMap (sz =>
            if (sz <= 1){
                Gen.const(Typ.TBool)
            } else {
                Gen.frequency(
                    1 -> Gen.const(Typ.TBool),
                    sz -> (for {
                        t1 <- Gen.resize(sz/2, genTyp())
                        t2 <- Gen.resize(sz/2, genTyp())
                    } yield (Typ.TFun(t1,t2)))
                )
            }
        )

    def genVar(g : List[Typ],t : Typ) : Gen[Option[Expr]] = {
        val vars = g.zipWithIndex.flatMap { (t2, i) => 
            if (t == t2) { Some(Some(Expr.Var(i))) } else { None }
        }
        vars match {
            case Nil => Gen.const(None)
            case _ => Gen.oneOf(vars)
        }
    }

    def genConst(t : Typ) : Gen[Expr] = {
        t match {
            case Typ.TBool => Gen.oneOf(true,false).map(b => Expr.Bool(b))
            case Typ.TFun(t1,t2) => genConst(t2).map(e => Expr.Abs(t1,e))
        }
    }

    def genExactExpr(g : List[Typ], t : Typ) : Gen[Expr] = {
        genVar(g,t).flatMap(me =>
            me match {
                case Some(e) => Gen.const(e)
                case None => Gen.size.flatMap(n =>
                    if(n <= 1){
                        genConst(t)
                    } else {
                        t match {
                            case Typ.TFun(t1, t2) => Gen.resize(n-1,genExactExpr(t1::g,t2)).map(e => Expr.Abs(t1,e))
                            case _ => (for {
                                t2 <- genTyp()
                                e1 <- Gen.resize(n/2,genExactExpr(g,Typ.TFun(t2,t)))
                                e2 <- Gen.resize(n/2,genExactExpr(g,t2))
                            } yield (Expr.App(e1,e2)))
                        }
                    }
                )
            }
        )
    }

    val gen = genTyp().flatMap(t => genExactExpr(Nil,t))
}