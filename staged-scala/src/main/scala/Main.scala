import scala.quoted.*

import org.scalacheck.Gen
import org.scalacheck.rng.Seed

import stagedgen.StGen
import BST.Bst
import BST.SingleBespoke
import BST.SingleBespokeStaged

val wg2 = Gen.frequency(
  2 -> 999,
  3 -> 111
)

@main def hello(): Unit =
  val seed = Seed.apply(11)
  val Some(a) = STLC.Bespoke.gen.apply(Gen.Parameters.default,seed)
  val b = STLC.BespokeStaged.gen(Gen.Parameters.default.size)(seed)
  println(s"Unsaged: ${a.toString}")
  println(s"Staged: ${b.toString}")