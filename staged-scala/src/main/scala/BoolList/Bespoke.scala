package BoolList
import org.scalacheck.Gen
import org.scalacheck.Arbitrary


object Bespoke {
    def go() : Gen[List[Boolean]] = {
        Gen.size.flatMap(sz =>
            if(sz <= 0){
                Gen.const(Nil)
            } else {
                for {
                    x <- Gen.oneOf(true,false)
                    xs <- Gen.resize(sz-1,go())
                } yield (x :: xs)
            }
        )
    }
  val gen = go()
}