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
  val seed = Seed.apply(10)
  val Some(a) = wg2.apply(Gen.Parameters.default,seed)
  val b = StGen.wg(Gen.Parameters.default.size)(seed)
  println(s"Unsaged: ${a.toString}")
  println(s"Staged: ${b.toString}")