package STLC

import scala.quoted.*
import stagedgen.Splittable
import stagedgen.SplittableCps
import stagedgen.Cps

enum Typ:
    case TBool
    case TFun(dom : Typ, cod : Typ)

enum TypS:
    case TBoolS
    case TFunS(dom : Expr[Typ], cod : Expr[Typ])

given [A : Type](using Quotes) : SplittableCps[Typ,TypS] with
    extension (a : Expr[Typ])
        def splitCps(using Quotes) : Cps[TypS] = Cps.cps([Z : Type] => k => '{
            ${a} match {
                case Typ.TBool => ${k(TypS.TBoolS)}
                case Typ.TFun(dom,cod) => ${k(TypS.TFunS('{dom},'{cod}))}
            }
        })


enum Term:
    case Var(idx : Long)
    case Bool(v : Boolean)
    case Abs(t : Typ, body : Term)
    case App(fun : Term, arg : Term)

given [A : Type](using Quotes) : SplittableCps[Term, Expr[Long] | Expr[Boolean] | (Expr[Typ],Expr[Term]) | (Expr[Term],Expr[Term]) ] with
    extension (a : Expr[Term])
        def splitCps(using Quotes) : Cps[Expr[Long] | Expr[Boolean] | (Expr[Typ],Expr[Term]) | (Expr[Term],Expr[Term]) ] = Cps.cps([Z : Type] => k => '{
            ${a} match {
                case Term.Var(x) => ${k('{x})}
                case Term.Bool(v) => ${k('{v})}
                case Term.Abs(t,body) => ${k('{t},'{body})}
                case Term.App(fun,arg) => ${k('{fun},'{arg})}
            }
        })
