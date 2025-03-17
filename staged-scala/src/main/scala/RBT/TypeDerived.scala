package RBT

import org.scalacheck.Gen

import org.scalacheck.Gen
import org.scalacheck.Arbitrary
import Rbt.*
import Color.*
import Nat.*

object TypeDerived {
    def go() : Gen[Rbt] = {
        Gen.size.flatMap (sz =>
            if(sz == 0){
                Gen.const(Rbt.E)
            } else {
                Gen.resize(sz - 1,
                    Gen.frequency(
                        1 -> Gen.const(Rbt.E),
                        1 -> (for {
                            c <- Gen.oneOf(Red,Black)
                            k <- Gen.Choose.chooseLong.choose(0, rbt_type_limits)
                            v <- Nat.generator(rbt_type_limits)
                            l <- go()
                            r <- go()
                        } yield Rbt.Node(c,l,k,v,r))
                    )
                )
            }
        )
    }

    val gen = go()
}