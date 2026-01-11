package benchmark

import java.util.concurrent.TimeUnit

import scala.quoted.*
import org.openjdk.jmh.annotations._
import org.scalacheck.Gen
import org.scalacheck.rng.*
import stagedgen.StGen
import BST.Bst
import RBT.Rbt
import STLC.*

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

val size10 = Gen.Parameters.default.withSize(10)
val size100 = Gen.Parameters.default.withSize(100)
val size1000 = Gen.Parameters.default.withSize(1000)
val size10000 = Gen.Parameters.default.withSize(10000)  // Added new size parameter

// Bool List Bespoke - unstaged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespoke10() = {
    BoolList.Bespoke.gen.apply(size10,Seed.random())
  }


@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespoke100() = {
    BoolList.Bespoke.gen.apply(size100,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespoke1000() = {
    BoolList.Bespoke.gen.apply(size1000,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespoke10000() = {
    BoolList.Bespoke.gen.apply(size10000,Seed.random())
  }

// Bool List Bespoke - staged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespokeStaged10() = {
    BoolList.BespokeStaged.gen(10)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespokeStaged100() = {
    BoolList.BespokeStaged.gen(100)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespokeStaged1000() = {
    BoolList.BespokeStaged.gen(1000)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBoolListBespokeStaged10000() = {
    BoolList.BespokeStaged.gen(10000)(Seed.random())
  }

// BST Type Derived - unstaged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstType10(): Option[Bst] = {
    BST.TypeDerived.gen.apply(size10,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstType100(): Option[Bst] = {
    BST.TypeDerived.gen.apply(size100,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstType1000(): Option[Bst] = {
    BST.TypeDerived.gen.apply(size1000,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstType10000(): Option[Bst] = {
    BST.TypeDerived.gen.apply(size10000,Seed.random())
  }
/*
// BST Type Derived - staged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstTypeStaged10(): Bst = {
    BST.TypeDerivedStaged.gen(10)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstTypeStaged100(): Bst = {
    BST.TypeDerivedStaged.gen(100)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstTypeStaged1000(): Bst = {
    BST.TypeDerivedStaged.gen(1000)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstTypeStaged10000(): Bst = {
    BST.TypeDerivedStaged.gen(10000)(Seed.random())
  }
*/
// BST Bespoke - unstaged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespoke10(): Option[Bst] = {
    BST.SingleBespoke.gen.apply(size10,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespoke100(): Option[Bst] = {
    BST.SingleBespoke.gen.apply(size100,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespoke1000(): Option[Bst] = {
    BST.SingleBespoke.gen.apply(size1000,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespoke10000(): Option[Bst] = {
    BST.SingleBespoke.gen.apply(size10000,Seed.random())
  }

// BST Bespoke - staged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespokeStaged10(): Bst = {
    BST.SingleBespokeStaged.gen(10)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespokeStaged100(): Bst = {
    BST.SingleBespokeStaged.gen(100)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespokeStaged1000(): Bst = {
    BST.SingleBespokeStaged.gen(1000)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateBstBespokeStaged10000(): Bst = {
    BST.SingleBespokeStaged.gen(10000)(Seed.random())
  }
/*
// RBT Type Derived - unstaged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtType10(): Option[Rbt] = {
    RBT.TypeDerived.gen.apply(size10,Seed.random())
  }


@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtType100(): Option[Rbt] = {
    RBT.TypeDerived.gen.apply(size100,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtType1000(): Option[Rbt] = {
    RBT.TypeDerived.gen.apply(size1000,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtType10000(): Option[Rbt] = {
    RBT.TypeDerived.gen.apply(size10000,Seed.random())
  }

// RBT Type Derived - staged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtTypeStaged10(): Rbt = {
    RBT.TypeDerivedStaged.gen(10)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtTypeStaged100(): Rbt = {
    RBT.TypeDerivedStaged.gen(100)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtTypeStaged1000(): Rbt = {
    RBT.TypeDerivedStaged.gen(1000)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateRbtTypeStaged10000(): Rbt = {
    RBT.TypeDerivedStaged.gen(10000)(Seed.random())
  }
*/
// STLC Term (Bespoke) - unstaged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTerm10(): Option[Term] = {
    STLC.Bespoke.gen.apply(size10,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTerm100(): Option[Term] = {
    STLC.Bespoke.gen.apply(size100,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTerm1000(): Option[Term] = {
    STLC.Bespoke.gen.apply(size1000,Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTerm10000(): Option[Term] = {
    STLC.Bespoke.gen.apply(size10000,Seed.random())
  }

// STLC Term (Bespoke) - staged benchmarks
@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTermStaged10(): Term = {
    STLC.BespokeStaged.gen(10)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTermStaged100(): Term = {
    STLC.BespokeStaged.gen(100)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTermStaged1000(): Term = {
    STLC.BespokeStaged.gen(1000)(Seed.random())
  }

@Benchmark
@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 3, time = 5, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 5, timeUnit = TimeUnit.SECONDS)
@Fork(1)
  def generateTermStaged10000(): Term = {
    STLC.BespokeStaged.gen(10000)(Seed.random())
  }
}