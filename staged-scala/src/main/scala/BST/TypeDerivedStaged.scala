package BST

import Bst.*
import stagedgen.StGen
import stagedgen.Splittable
import stagedgen.Splittable.given
import stagedgen.SplittableCps.given
import scala.quoted.*

object TypeDerivedStaged {
    def go(using Quotes) : StGen[Expr[Bst]] = {
        StGen.recursive[Bst,Unit](
            rh => _ =>
            StGen.size.flatMap (sz =>
                '{$sz == 0}.split.flatMap(eqz =>
                    if(eqz){
                        StGen.pure('{Bst.E})
                    } else {
                        StGen.resize('{$sz - 1},
                            StGen.frequency(
                                '{1} -> StGen.pure('{Bst.E}),
                                '{1} -> (for {
                                    k <- StGen.chooseLong('{0}, '{bst_type_limits})
                                    v <- Nat.staged_generator('{bst_type_limits})
                                    l <- rh('{()})
                                    r <- rh('{()})
                                } yield ('{Bst.Node($l,$k,$v,$r)}))
                            )
                        )
                    }
                )
            )
        )('{()})
    }

    def genStaged (using Quotes) = StGen.splat(go)

    inline def gen = {
        ${genStaged}
    }

}

// if(sz == 0){
//                 Gen.const(Bst.E)
//             } else {
//                 Gen.resize(sz - 1,
//                     Gen.frequency(
//                         1 -> Bst.E,
//                         1 -> (for {
//                             k <- Gen.Choose.chooseLong.choose(0, bst_bespoke_limits)
//                             v <- Nat.generator(bst_bespoke_limits)
//                             l <- go()
//                             r <- go()
//                         } yield Bst.Node(l,k,v,r))
//                     )
//                 )
//             }