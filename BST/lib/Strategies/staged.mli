module Staged : sig
    include Base_quickcheck.Test.S with type t = Impl.tree
  
    val quickcheck_generator : t Base_quickcheck.Generator.t
  end
  