package benchmark

import java.util.concurrent.TimeUnit

import scala.quoted.*
import org.openjdk.jmh.annotations._
import org.scalacheck.Gen
import org.scalacheck.rng.*
import stagedgen.StGen
import BST.Bst
import BST.SingleBespoke
import BST.SingleBespokeStaged

def complexGen: Gen[(Long,Long)] = for {
    x <- Gen.choose(1,1000)
    y <- Gen.choose(0,x)
  } yield (x,y)

class IllegalBoundsError[A](low: A, high: A)
    extends IllegalArgumentException(s"invalid bounds: low=$low, high=$high")

def chLng(l: Long, h: Long)(p: Gen.Parameters, seed: Seed): (Option[Long],Seed) = {
      if (h < l) {
        throw new IllegalBoundsError(l, h)
      } else if (h == l) {
        (Some(l),seed)
      } else if (l == Long.MinValue && h == Long.MaxValue) {
        val (n, s) = seed.long
        (Some(n), s)
      } else if (l == Int.MinValue && h == Int.MaxValue) {
        val (n, s) = seed.long
        (Some(n.toInt.toLong), s)
      } else if (l == Short.MinValue && h == Short.MaxValue) {
        val (n, s) = seed.long
        (Some(n.toShort.toLong), s)
      } else if (l == 0L && h == Char.MaxValue) {
        val (n, s) = seed.long
        (Some(n.toChar.toLong),s)
      } else if (l == Byte.MinValue && h == Byte.MaxValue) {
        val (n, s) = seed.long
        (Some(n.toByte.toLong), s)
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
          (Some(n), s)
        } else {
          val (n, s) = seed.long
          (Some(l + (n & 0x7fffffffffffffffL) % d), s)
        }
      }
    }

  def complexGenInlined : (Gen.Parameters, Seed) => (Option[(Long,Long)],Seed) = {
    (p,seed) =>
      val (x,seed2) = chLng(0,1000)(p,seed)
      x match {
        case None => (None,seed2)
        case Some(x) =>
          val (y,seed3) = chLng(0,x)(p,seed2)
          y match {
            case None => (None,seed)
            case Some(y) => (Some(x,y),seed3)
          }
      }
  }



// @State(Scope.Thread)
// class GenBm {
// @Benchmark
// @BenchmarkMode(Array(Mode.AverageTime))
// @OutputTimeUnit(TimeUnit.NANOSECONDS)
// @Warmup(iterations = 2, time = 5, timeUnit = TimeUnit.SECONDS)
// @Measurement(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
// @Fork(1)
//   def generateComplexBase(): Option[(Long,Long)] = {
//     complexGen.sample
//   }

// @Benchmark
// @BenchmarkMode(Array(Mode.AverageTime))
// @OutputTimeUnit(TimeUnit.NANOSECONDS)
// @Warmup(iterations = 2, time = 5, timeUnit = TimeUnit.SECONDS)
// @Measurement(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
// @Fork(1)
//   def generateComplexSt(): Option[(Long,Long)] = {
//     StGen.complexStGen(Gen.Parameters.default.size)(Seed.random())
//   }

// @Benchmark
// @BenchmarkMode(Array(Mode.AverageTime))
// @OutputTimeUnit(TimeUnit.NANOSECONDS)
// @Warmup(iterations = 2, time = 5, timeUnit = TimeUnit.SECONDS)
// @Measurement(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
// @Fork(1)
//   def generateComplexInlined(): Option[(Long,Long)] = {
//     (complexGenInlined(Gen.Parameters.default,Seed.random()))(0)
//   }
// }



@State(Scope.Thread)
class GenBm {
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBst(): Option[Bst] = {
    SingleBespoke.gen.sample
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstStaged(): Bst = {
    SingleBespokeStaged.gen(Gen.Parameters.default.size)(Seed.random())
  }
}