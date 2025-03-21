package BST

import stagedgen.StGen
import stagedgen.Splittable
import stagedgen.Splittable.given
import stagedgen.SplittableCps.given
import scala.quoted.*
import Nat.*

object SingleBespokeStaged {
    def go(using Quotes)(lo : Expr[Long], hi : Expr[Long]) : StGen[Expr[Bst]] = {
        StGen.recursive(
            (rec : Expr[(Long,Long)] => StGen[Expr[Bst]]) =>
            (lohi : Expr[(Long,Long)]) =>
            lohi.split.flatMap((lo,hi) =>
            StGen.size.flatMap (sz =>
                '{${lo} >= ${hi} || ${sz} <= 1}.split.flatMap(b =>
                if(b){
                    StGen.pure('{Bst.E})
                } else {
                    StGen.frequency(
                        '{1} -> StGen.pure('{Bst.E}),
                        sz -> (for{
                            k <- StGen.chooseLong(lo,hi)
                            v <- Nat.staged_generator('{bst_bespoke_limits})
                            l <- StGen.resize('{${sz}/2}, rec('{(${lo}, ${k}-1)}))
                            r <- StGen.resize ('{${sz}/2}, rec('{(${k} + 1, ${hi})}))
                        } yield ('{Bst.Node (${l},${k},${v},${r})}))
                    )
                }
            )
            )
        )
        )('{(${lo},${hi})})
    }

    def genStaged (using Quotes) = StGen.splat (go('{0},'{bst_bespoke_limits}))

    inline def gen = {
        ${genStaged}
    }
}


