open Impl
open Core

module BaseTypeStaged : Base_quickcheck.Test.S with type t = rbt = struct
  type t = rbt [@@deriving sexp, quickcheck]

  let quickcheck_generator =
    let rec quickcheck_generator_tree =
      lazy
        (let quickcheck_generator_tree =
           Base_quickcheck.Generator.of_lazy quickcheck_generator_tree
         in
         Base_quickcheck.Generator.create (fun ~size ~random ->
           if size = 0 then
            (if Float.(Splittable_random.float random ~lo:0. ~hi:0.1 >= 0.) then E else E)
           else
             let adjusted_size = Base.Int.pred size in
             if Float.(Splittable_random.float random ~lo:0. ~hi:0.2 >= 0.1) then
               T (
                 (if Float.(Splittable_random.float random ~lo:0. ~hi:0.2 >= 0.1) then Impl.B else Impl.R),
                 (Base_quickcheck.Generator.generate
                    quickcheck_generator_tree
                    ~size:adjusted_size
                    ~random),
                 ((Splittable_random.int random
                     ~lo:Int.min_value ~hi:Int.max_value) mod 128),
                 ((Splittable_random.int random
                     ~lo:Int.min_value ~hi:Int.max_value) mod 128),
                 (Base_quickcheck.Generator.generate
                    quickcheck_generator_tree
                    ~size:adjusted_size
                    ~random)
               )
             else
               E))
    in
    Base_quickcheck.Generator.of_lazy quickcheck_generator_tree
end