package BST
import org.scalacheck.Gen
import org.scalacheck.Arbitrary

import Bst.*
import Nat.*

object SingleBespoke {
  def go (lo : Long, hi : Long): Gen[Bst] = {
    Gen.size.flatMap (sz =>
      if (lo >= hi || sz <= 1) {
        Gen.const(Bst.E)
      } else {
        for {
        k <- Gen.Choose.chooseLong.choose(lo, hi)
        v <- Nat.generator(bst_bespoke_limits)
        l <- Gen.resize(sz / 2, go(lo, k - 1))
        r <- Gen.resize (sz / 2, go(k + 1, hi))
        } yield (Bst.Node (l,k,v,r))
      }
    )
  }

  val gen = go(0,bst_bespoke_limits)
}