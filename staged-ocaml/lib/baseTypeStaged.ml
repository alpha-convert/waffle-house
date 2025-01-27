open Impl
open Core

module BaseTypeStaged : Base_quickcheck.Test.S with type t = rbt = struct
  type t = rbt [@@deriving sexp, quickcheck]

  let quickcheck_generator =
    let rec quickcheck_generator_tree =
      lazy
        (let quickcheck_generator_tree =
           Base_quickcheck.Generator.of_lazy quickcheck_generator_tree in
         let _gen__022_ =
           Base_quickcheck.Generator.create (fun ~size:_ ~random:_ -> E) in
         let _gen__020_ =
           Base_quickcheck.Generator.create
             (fun ~size ~random ->
                let adjusted_size = Base.Int.pred size in
                T (
                  (if Splittable_random.bool random then Impl.R else Impl.B),
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
                )) in
         let _gen__023_ =
           Base_quickcheck.Generator.create (fun ~size ~random ->
             let float_value =
               Splittable_random.float random ~lo:0. ~hi:0.2 in
             if Float.(>=) float_value 0.1 then
               Base_quickcheck.Generator.generate _gen__020_ ~size ~random
             else
               Base_quickcheck.Generator.generate _gen__022_ ~size ~random)
         in
         Base_quickcheck.Generator.create (fun ~size ~random ->
           if size = 0 then
             Base_quickcheck.Generator.generate _gen__022_ ~size ~random
           else
             Base_quickcheck.Generator.generate _gen__023_ ~size ~random)) in
    Base_quickcheck.Generator.of_lazy quickcheck_generator_tree
end