package benchmark

import java.util.concurrent.TimeUnit

import scala.quoted.*
import org.openjdk.jmh.annotations._
import org.scalacheck.Gen
import org.scalacheck.rng.*
import stagedgen.StGen

@BenchmarkMode(Array(Mode.AverageTime))
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 2, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 3, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
@State(Scope.Thread)

  def complexGen: Gen[(Long,Long)] = for {
    x <- Gen.choose(1,1000)
    y <- Gen.choose(0,x)
  } yield (x,y)

class GenBm {
@Benchmark
  def generateComplexBase(): Option[(Long,Long)] = {
    complexGen.sample
  }

@Benchmark
  def generateComplexSt(): Option[(Long,Long)] = {
    StGen.complexStGen(Gen.Parameters.default)(Seed.random())
  }
}