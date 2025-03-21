package BoolList
import stagedgen.StGen
import stagedgen.Splittable
import stagedgen.Splittable.given
import stagedgen.SplittableCps.given
import scala.quoted.*
import Nat.*


object BespokeStaged {
    def go(using Quotes) : StGen[Expr[List[Boolean]]] = {
        StGen.recursive[List[Boolean],Unit](rh => _ =>
            StGen.size.flatMap(sz =>
                '{$sz <= 0}.split.flatMap(leq =>
                    if(leq){
                        StGen.pure('{Nil})
                    } else {
                        for {
                            x <- StGen.oneOf('{true},'{false})
                            xs <- StGen.resize('{$sz-1},rh('{()}))
                        } yield ('{$x :: $xs})
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