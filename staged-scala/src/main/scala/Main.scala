import scala.quoted.*

import org.scalacheck.Gen
import org.scalacheck.rng.Seed

import stagedgen.StGen


@main def hello(): Unit =
  val u = StGen.complexStGen
  val v = u(Gen.Parameters.default)(Seed.random())
  println(v)