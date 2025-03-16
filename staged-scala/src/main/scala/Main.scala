import scala.quoted.*

import org.scalacheck.Gen
import org.scalacheck.rng.Seed

import stagedgen.StGen
import BST.Bst
import BST.SingleBespoke
import BST.SingleBespokeStaged

@main def hello(): Unit =
  val seed = Seed.random()
  val Some(a) = SingleBespoke.gen.apply(Gen.Parameters.default,seed)
  val b = SingleBespokeStaged.gen(Gen.Parameters.default.size)(seed)
  println(a.toString)
  println(b.toString)