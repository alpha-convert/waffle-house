package Nat

import org.scalacheck.Gen
import org.scalacheck.Arbitrary
import scala.quoted.*

import stagedgen.StGen

case class Nat(value: Long) {}

object Nat {
  def generator (limit : Long): Gen[Nat] = 
    Gen.Choose.chooseLong.choose(Long.MinValue, Long.MaxValue).map(i => Nat(i % limit))

  def staged_generator (limit : Expr[Long]) (using Quotes) : StGen[Expr[Nat]] =
    StGen.chooseLong('{Long.MinValue},'{Long.MaxValue}).map(cl => '{Nat(${cl} % ${limit})})

  extension (a: Nat)
    def <(b: Nat): Boolean = natOrdering.lt(a, b)
    def <=(b: Nat): Boolean = natOrdering.lteq(a, b)
    def >(b: Nat): Boolean = natOrdering.gt(a, b)
    def >=(b: Nat): Boolean = natOrdering.gteq(a, b)
  
  implicit val natOrdering: Ordering[Nat] = Ordering.by(_.value)
}
