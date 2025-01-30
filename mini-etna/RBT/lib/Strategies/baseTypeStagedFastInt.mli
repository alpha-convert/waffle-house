module BaseTypeStagedFastInt : sig
    include Base_quickcheck.Test.S with type t = Impl.rbt
  
    val quickcheck_generator : t Base_quickcheck.Generator.t
  end
  