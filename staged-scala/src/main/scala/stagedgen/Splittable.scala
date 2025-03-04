package stagedgen

import scala.quoted.*
import stagedgen.Cps

trait Splittable[T : Type,S] {
    extension (a : Expr[T]) def split(using Quotes) : Cps[S]
}

given (using Quotes) : Splittable[Boolean,Boolean] with
    extension (a : Expr[Boolean])
        def split(using Quotes) : Cps[Boolean] = Cps.cps([Z : Type] => (k : Boolean => Expr[Z]) => '{
            if ${a} then ${k(true)} else ${k(false)}
        })

given [A : Type, B : Type](using Quotes) : Splittable[(A,B),(Expr[A],Expr[B])] with
    extension (a : Expr[(A,B)])
        def split(using Quotes) : Cps[(Expr[A],Expr[B])] = Cps.cps([Z : Type] => k => '{
            val (x,y) = ${a}
            ${k('{x},'{y})}
        })

given [A : Type](using Quotes) : Splittable[Option[A],Option[Expr[A]]] with
    extension (a : Expr[Option[A]])
        def split(using Quotes) : Cps[Option[Expr[A]]] = Cps.cps([Z : Type] => k => '{
            ${a} match {
                case None => ${k(None)}
                case Some(v) => ${k(Some('{v}))}
            }
        })

given [A : Type](using Quotes) : Splittable[List[A],Either[Unit,(Expr[A],Expr[List[A]])]] with
    extension (a : Expr[List[A]])
        def split(using Quotes) : Cps[Either[Unit,(Expr[A],Expr[List[A]])]] = Cps.cps([Z : Type] => k => '{
            ${a} match {
                case Nil => ${k(Left(()))}
                case hd :: tl => ${k(Right(('{hd},'{tl})))}
            }
        })