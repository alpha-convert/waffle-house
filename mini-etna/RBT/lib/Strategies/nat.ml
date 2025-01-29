module Nat = struct
  include Core.Int

  type t = Core.Int.t [@@deriving sexp, quickcheck]
  include Core
  
  let quickcheck_generator =
    Base_quickcheck.Generator.bind
      (Base_quickcheck.Generator.create (fun ~size:_ ~random ->
         Splittable_random.int random ~lo:Int.min_value ~hi:Int.max_value))
      ~f:(fun number ->
        Base_quickcheck.Generator.return (number mod 128))

end
