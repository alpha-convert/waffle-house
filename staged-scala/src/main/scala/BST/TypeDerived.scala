package BST

import org.scalacheck.Gen

import org.scalacheck.Gen
import org.scalacheck.Arbitrary

import Bst.*

object TypeDerived {
    def go() : Gen[Bst] = {
        Gen.size.flatMap (sz =>
            if(sz == 0){
                Gen.const(Bst.E)
            } else {
                Gen.resize(sz - 1,
                    Gen.frequency(
                        1 -> Gen.const(Bst.E),
                        1 -> (for {
                            k <- Gen.Choose.chooseLong.choose(0, bst_type_limits)
                            v <- Nat.generator(bst_type_limits)
                            l <- go()
                            r <- go()
                        } yield Bst.Node(l,k,v,r))
                    )
                )
            }
        )
    }

    val gen = go()
}