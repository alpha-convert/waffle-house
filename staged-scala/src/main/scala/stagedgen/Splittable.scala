package stagedgen

import scala.quoted.*
import stagedgen.Cps
import stagedgen.StGen

trait SplittableCps[T : Type,S] {
    extension (a : Expr[T]) def splitCps(using Quotes) : Cps[S]
}

object SplittableCps {
given (using Quotes) : SplittableCps[Boolean,Boolean] with
    extension (a : Expr[Boolean])
        def splitCps(using Quotes) : Cps[Boolean] = Cps.cps([Z : Type] => (k : Boolean => Expr[Z]) => '{
            if ${a} then ${k(true)} else ${k(false)}
        })

given [A : Type, B : Type](using Quotes) : SplittableCps[(A,B),(Expr[A],Expr[B])] with
    extension (a : Expr[(A,B)])
        def splitCps(using Quotes) : Cps[(Expr[A],Expr[B])] = Cps.cps([Z : Type] => k => '{
            val (x,y) = ${a}
            ${k('{x},'{y})}
        })

given [A : Type](using Quotes) : SplittableCps[Option[A],Option[Expr[A]]] with
    extension (a : Expr[Option[A]])
        def splitCps(using Quotes) : Cps[Option[Expr[A]]] = Cps.cps([Z : Type] => k => '{
            ${a} match {
                case None => ${k(None)}
                case Some(v) => ${k(Some('{v}))}
            }
        })

given [A : Type](using Quotes) : SplittableCps[List[A],Either[Unit,(Expr[A],Expr[List[A]])]] with
    extension (a : Expr[List[A]])
        def splitCps(using Quotes) : Cps[Either[Unit,(Expr[A],Expr[List[A]])]] = Cps.cps([Z : Type] => k => '{
            ${a} match {
                case Nil => ${k(Left(()))}
                case hd :: tl => ${k(Right(('{hd},'{tl})))}
            }
        })
}

trait Splittable[T : Type,S] {
    extension (a : Expr[T]) def split(using Quotes) : StGen[S]
}

object Splittable {
    given [T: Type, S](using cps: SplittableCps[T, S])(using Quotes): Splittable[T, S] with {
    extension (a: Expr[T]) 
        def split(using q: Quotes): StGen[S] = {
            StGen.gen((_,seed) =>
                (a.splitCps(using q)).flatMap (s =>
                    Cps.pure(s,seed)
                )
            )
        }
    }
}