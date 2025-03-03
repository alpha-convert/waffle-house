import scala.quoted.*

import org.scalacheck.Gen
import org.scalacheck.rng.Seed

import stagedgen.StGen

def fooImpl(using Quotes) = {
  val e = StGen.splat(StGen.pure('{55}))
  println(s"Generated code: ${e.show}")
  e
}

inline def foo() = {
  ${fooImpl}
}

def sample[T](f : Gen.Parameters => Seed => Option[T]) = {
  f(Gen.Parameters.default)(Seed.random())
}


def msg = "I was compiled by Scala 3. :)"

@main def hello(): Unit =
  println("Hello world!")
  println(msg)


