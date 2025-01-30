open Impl
open Core

module BaseTypeStagedFastInt : Base_quickcheck.Test.S with type t = rbt = struct
  type t = rbt [@@deriving sexp, quickcheck]

  let quickcheck_generator =
    let rec quickcheck_generator_tree ~size ~random =
           if size = 0 then
            (if (Float.(>=)) (Unboxed_splitmix.DropIn.float random ~lo:0. ~hi:0.1) 0. then E else E)
           else
             let adjusted_size = Base.Int.pred size in
             if Float.(Unboxed_splitmix.DropIn.float random ~lo:0. ~hi:0.2 >= 0.1) then
               T (
                 (if Float.(Unboxed_splitmix.DropIn.float random ~lo:0. ~hi:0.2 >= 0.1) then Impl.B else Impl.R),
                 (
                    quickcheck_generator_tree
                    ~size:adjusted_size
                    ~random),
                 ((Unboxed_splitmix.DropIn.int random
                     ~lo:Int.min_value ~hi:Int.max_value) mod 128),
                 ((Unboxed_splitmix.DropIn.int random
                     ~lo:Int.min_value ~hi:Int.max_value) mod 128),
                 (quickcheck_generator_tree
                    ~size:adjusted_size
                    ~random)
               )
             else
               E
    in
    Quickcheck.Generator.create quickcheck_generator_tree
end