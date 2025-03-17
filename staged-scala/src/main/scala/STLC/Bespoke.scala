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

    def genVar(g : List[Typ],t : Typ) : Gen[Option[Term]] = {
        val vars = g.zipWithIndex.flatMap { (t2, i) => 
            if (t == t2) { Some(Some(Term.Var(i))) } else { None }
        }
        vars match {
            case Nil => Gen.const(None)
            case _ => Gen.oneOf(vars)
        }
    }

    def genConst(t : Typ) : Gen[Term] = {
        t match {
            case Typ.TBool => Gen.oneOf(true,false).map(b => Term.Bool(b))
            case Typ.TFun(t1,t2) => genConst(t2).map(e => Term.Abs(t1,e))
        }
    }

    def genExactTerm(g : List[Typ], t : Typ) : Gen[Term] = {
        genVar(g,t).flatMap(me =>
            me match {
                case Some(e) => Gen.const(e)
                case None => Gen.size.flatMap(n =>
                    if(n <= 1){
                        genConst(t)
                    } else {
                        t match {
                            case Typ.TFun(t1, t2) => Gen.resize(n-1,genExactTerm(t1::g,t2)).map(e => Term.Abs(t1,e))
                            case _ => (for {
                                t2 <- genTyp()
                                e1 <- Gen.resize(n/2,genExactTerm(g,Typ.TFun(t2,t)))
                                e2 <- Gen.resize(n/2,genExactTerm(g,t2))
                            } yield (Term.App(e1,e2)))
                        }
                    }
                )
            }
        )
    }

    val gen = genTyp().flatMap(t => genExactTerm(Nil,t))
}