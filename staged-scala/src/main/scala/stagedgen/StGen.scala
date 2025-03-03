package stagedgen

import org.scalacheck.Gen
import org.scalacheck.rng.Seed
import scala.quoted.*
import stagedgen.Cps

class IllegalBoundsError[A](low: A, high: A)
    extends IllegalArgumentException(s"invalid bounds: low=$low, high=$high")

private def chLng(l: Long, h: Long)(p: Gen.Parameters, seed: Seed): (Long,Seed) = {
      if (h < l) {
        throw new IllegalBoundsError(l, h)
      } else if (h == l) {
        ((l),seed)
      } else if (l == Long.MinValue && h == Long.MaxValue) {
        val (n,s) = seed.long
        ((n),s)
      } else if (l == Int.MinValue && h == Int.MaxValue) {
        val (n, s) = seed.long
        ((n.toInt.toLong), s)
      } else if (l == Short.MinValue && h == Short.MaxValue) {
        val (n, s) = seed.long
        ((n.toShort.toLong), s)
      } else if (l == 0L && h == Char.MaxValue) {
        val (n, s) = seed.long
        ((n.toChar.toLong), s)
      } else if (l == Byte.MinValue && h == Byte.MaxValue) {
        val (n, s) = seed.long
        ((n.toByte.toLong), s)
      } else {
        val d = h - l + 1
        if (d <= 0) {
          var tpl = seed.long
          var n = tpl._1
          var s = tpl._2
          while (n < l || n > h) {
            tpl = s.long
            n = tpl._1
            s = tpl._2
          }
          ((n), s)
        } else {
          val (n, s) = seed.long
          ((l + (n & 0x7fffffffffffffffL) % d), s)
        }
      }
    }

abstract class StGen[T] { self =>
  def doApply(p : Expr[Gen.Parameters],seed:Expr[Seed]) : Cps[(Option[T],Expr[Seed])]

  

  def map[S](f : T => S) : StGen[S] = {
    StGen.gen((p,seed) =>
        self.doApply(p,seed).map((ot,seed2) => (ot.map(f),seed2))
    )
  }

  def flatMap[S](f : T => StGen[S]) : StGen[S] = {
    StGen.gen((p,seed) =>
        self.doApply(p,seed).flatMap((ot,seed2) =>
          ot match {
            case None => Cps.pure((None,seed))
            case Some(t) => f(t).doApply(p,seed2)
          }
        )
    )
  }

  
}

object StGen {

  def gen[T](f : (Expr[Gen.Parameters],Expr[Seed]) => Cps[(Option[T],Expr[Seed])]) : StGen[T] = {
    new StGen[T]{
      def doApply(p : Expr[Gen.Parameters],seed:Expr[Seed]) = {
        f(p,seed)
      }
    }
  }
  def pure[T](t: T): StGen[T] = new StGen[T] {
    def doApply(p : Expr[Gen.Parameters],seed:Expr[Seed]) : Cps[(Option[T],Expr[Seed])] = {
      Cps.pure((Some(t),seed))
    }
  }

  def chooseLong(lo : Expr[Long],hi:Expr[Long])(using Quotes) : StGen[Expr[Long]] = {
    StGen.gen((p,seed) =>
        for {
            (x,y) <- Cps.splitPair('{chLng(${lo},${hi})(${p},${seed})})
        } yield (Some(x),y)
    )
  }

  def splat[T : Type](g : StGen[Expr[T]])(using Quotes) : Expr[Gen.Parameters => Seed => Option[T]] = {
    '{
        (p : Gen.Parameters) => (seed : Seed) =>
        ${Cps.run(g.doApply('{p},'{seed}).map((x,seed2) => x match {
            case None => '{None}
            case Some(value) => '{Some(${value})}
        }))}
    }
  }

  def print[T : Type](g : StGen[Expr[T]])(using Quotes) : Unit = {
      val s = splat(g).show
      println(s"Generator: $s")
  }

  def complexStGenImpl (using Quotes): Expr[Gen.Parameters => Seed => Option[(Long,Long)]] =
    StGen.splat(for {
        x <- StGen.chooseLong('{1},'{1000})
        y <- StGen.chooseLong('{0},x)
    } yield '{(${x},${y})}
    )

  inline def complexStGen = {
    ${complexStGenImpl}
  }
}

