package stagedgen

import scala.quoted.*
import org.scalacheck.rng.Seed

abstract class Cps[T] { self =>
  def apply[Z : Type](cont: T => Expr[Z]): Expr[Z]

  def map[S](f : T => S) : Cps[S] = {
    new Cps {
      def apply[Z : Type](cont: S => Expr[Z]): Expr[Z] = {
        self.apply((x : T) => cont(f(x)))
      }
    }
  }

  def flatMap[S](f : T => Cps[S]) : Cps[S] = {
    new Cps {
      // I think this is correct?
      def apply[Z : Type](cont: S => Expr[Z]): Expr[Z] = {
        self.apply((x : T) => f(x).apply(cont))
      }
    }
  }
}

object Cps {
  def pure[T](t: T): Cps[T] = new Cps[T] {
    def apply[Z : Type](cont: T => Expr[Z]): Expr[Z] = cont(t)
  }

  def cps[T](f : [Z : Type] => (T => Expr[Z]) => Expr[Z]) : Cps[T] = {
    new Cps[T]{
      def apply[Z : Type](cont: T => Expr[Z]): Expr[Z] = f(cont)
    }
  }

  def run[T : Type](c : Cps[Expr[T]]) : Expr[T] = {
    c.apply(x => x)
  }

  def letInsert[T : Type](ex : Expr[T])(using Quotes) : Cps[Expr[T]] = new Cps[Expr[T]] {
    def apply[Z : Type](cont: Expr[T] => Expr[Z]): Expr[Z] =
      '{
        val x = ${ex}
        ${cont('{x})}
      }
  }

  def splitPair[S: Type, T : Type](ex : Expr[(S,T)])(using Quotes) : Cps[(Expr[S],Expr[T])] = new Cps[(Expr[S],Expr[T])] {
    def apply[Z : Type](cont: ((Expr[S],Expr[T])) => Expr[Z]): Expr[Z] =
      '{
        val (x,y) = ${ex}
        ${cont('{x},'{y})}
      }
  }
}