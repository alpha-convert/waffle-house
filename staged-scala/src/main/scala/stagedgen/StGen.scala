package stagedgen

import org.scalacheck.rng.Seed
import scala.quoted.*
import stagedgen.Cps
import stagedgen.Splittable
import stagedgen.SplittableCps.given
import stagedgen.Splittable.given

class IllegalBoundsError[A](low: A, high: A)
    extends IllegalArgumentException(s"invalid bounds: low=$low, high=$high")

private def chLng(l: Long, h: Long)(size: Int, seed: Seed): (Long,Seed) = {
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
  def doApply(p : Expr[Int],seed:Expr[Seed]) : Cps[(T,Expr[Seed])]
  

  def map[S](f : T => S) : StGen[S] = {
    StGen.gen((p,seed) =>
        self.doApply(p,seed).flatMap((res,seed2) =>
          Cps.pure((f(res),seed2))
        )
    )
  }

  def flatMap[S](f : T => StGen[S]) : StGen[S] = {
    StGen.gen((size,seed) =>
        self.doApply(size,seed).flatMap((t,seed2) => f(t).doApply(size,seed2))
    )
  }
}

object StGen {

  def gen[T](f : (Expr[Int],Expr[Seed]) => Cps[(T,Expr[Seed])]) : StGen[T] = {
    new StGen[T]{
      def doApply(p : Expr[Int],seed:Expr[Seed]) = {
        f(p,seed)
      }
    }
  }
  def pure[T](t: T): StGen[T] = new StGen[T] {
    def doApply(p : Expr[Int],seed:Expr[Seed]) : Cps[(T,Expr[Seed])] = {
      Cps.pure((t,seed))
    }
  }

  def chooseLong(lo : Expr[Long],hi:Expr[Long])(using Quotes) : StGen[Expr[Long]] = {
    StGen.gen((p,seed) =>
        for {
            (x,y) <- ('{chLng(${lo},${hi})(${p},${seed})}).splitCps
        } yield (x,y)
    )
  }

  // def letInsert[T : Type](ex : Expr[T])(using Quotes) : Cps[Expr[T]] = new Cps[Expr[T]] {
  //   def apply[Z : Type](cont: Expr[T] => Expr[Z]): Expr[Z] =
  //     '{
  //       val x = ${ex}
  //       ${cont('{x})}
  //     }
  // }


  private def letInsert[T : Type](ex : Expr[T])(using Quotes) : StGen[Expr[T]] = {
    gen((_,seed) => Cps.letInsert(ex).map(u => (u,seed)))
  }


  def pick[T : Type](gs : (Expr[Int],StGen[Expr[T]])*)(acc : Expr[Long])(using Quotes) : StGen[Expr[T]] = {
    gs.toList match {
      case Nil => StGen.gen((_,_) => Cps.error('{"Fell off the end of pick list"}))
      case (x,g)::gs2 =>
        '{$acc <= $x}.split.flatMap(leq =>
          if(leq){
            g
          } else {
            letInsert('{$acc - $x}).flatMap(acc2 =>
              pick(gs2*)(acc2)
            )
          }
        )
    }
  }

  def frequency[T : Type](gs : (Expr[Int],StGen[Expr[T]])*)(using Quotes) : StGen[Expr[T]] = {
    val sum = gs.map(_._1).foldRight('{0L})((x,y) => '{${x}.toLong + ${y}})
    chooseLong('{1L},sum).flatMap(pick(gs*))
  }

  //  def frequency[T](gs: (Int, Gen[T])*): Gen[T] = {
  //   val filtered = gs.iterator.filter(_._1 > 0).toVector
  //   if (filtered.isEmpty) {
  //     throw new IllegalArgumentException("no items with positive weights")
  //   } else {
  //     var total = 0L
  //     val builder = TreeMap.newBuilder[Long, Gen[T]]
  //     filtered.foreach { case (weight, value) =>
  //       total += weight
  //       builder += ((total, value))
  //     }
  //     val tree = builder.result()
  //     choose(1L, total).flatMap(r => tree.rangeFrom(r).head._2)
  //   }
  // }

  def sized[T](f: Expr[Int] => StGen[T]): StGen[T] =
    gen { (size, seed) => f(size).doApply(size, seed) }

  def size : StGen[Expr[Int]] =
    sized(x => pure(x))

  def resize[T](size : Expr[Int], g : StGen[T]) : StGen[T] =
    gen { (_,seed) => g.doApply(size,seed) }

  def splat[T : Type](g : StGen[Expr[T]])(using Quotes) : Expr[Int => Seed => T] = {
    '{
        (size : Int) => (seed : Seed) =>
        ${Cps.run(g.doApply('{size},'{seed}).map((x,seed2) => x))}
    }
  }

  def print[T : Type](g : StGen[Expr[T]])(using Quotes) : Unit = {
      val s = splat(g).show
      println(s"Generator: $s")
  }


  def recursive[A : Type,R : Type](using Quotes)(step : (Expr[R] => StGen[Expr[A]]) => Expr[R] => StGen[Expr[A]])(x0 : Expr[R]): StGen[Expr[A]]=  {
    StGen.gen((size,random) =>
      ('{
        def go(x : R,size : Int,random: Seed) : (A,Seed) = {
          ${
            Cps.run(
              step(xc => StGen.gen((size,random) => ('{go(${xc},${size},${random})}).splitCps)
              )('{x}).doApply('{size},'{random}).flatMap((a,b) =>
                Cps.pure('{(${a},${b})})
              )
            )
          }
        }
        go(${x0},${size},${random})
      }
      ).splitCps
    )
  }
  //   type ('a,'r) recgen = 'r code -> 'a code t
  // let recurse f x = {
  //   rand_gen = fun ~size_c ~random_c ->
  //     Codecps.bind ((f x).rand_gen ~size_c ~random_c) @@ fun c ->
  //     Codecps.let_insert c
  // }

  // let recursive (type a) (type r) (x0 : r code) (step : (a,r) recgen -> r code -> a code t) =
  //   {
  //     rand_gen = fun ~size_c ~random_c -> 
  //       Codecps.bind (Codecps.let_insertv x0) @@ fun x0 ->
  //       (* let%bind x0 = Codecps.let_insert x0 in *)
  //       Codecps.let_insert @@ .< let rec go x ~size ~random = .~(
  //           Codecps.code_generate @@
  //             (step
  //                 (fun xc' -> { rand_gen = fun ~size_c ~random_c -> Codecps.return .< go .~xc' ~size:.~size_c ~random:.~random_c >. })
  //                 .<x>.
  //             ).rand_gen ~size_c:.<size>. ~random_c:.<random>.
  //         )
  //         in
  //           go .~(v2c x0) ~size:.~size_c ~random:.~random_c
  //       >.
  //   }

  def wgImpl (using q : Quotes): Expr[Int => Seed => Int] = {
    val e = StGen.splat(
      StGen.frequency(
        '{2} -> StGen.pure('{999}),
        '{3} -> StGen.pure('{111})
      )
    )
    e
  }

  inline def wg = {
    ${wgImpl}
  }
}

