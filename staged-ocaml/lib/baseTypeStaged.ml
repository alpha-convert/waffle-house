open Impl
open Core

module BaseTypeStaged : Base_quickcheck.Test.S with type t = rbt = struct
  type t = rbt [@@deriving sexp, quickcheck]
  let quickcheck_generator =
    let rec quickcheck_generator_tree =
      lazy
        (let quickcheck_generator_tree =
           Base_quickcheck.Generator.of_lazy quickcheck_generator_tree in
         let _pair__024_ =
           (1.,
            (Base_quickcheck.Generator.create
               (fun ~size:_size__028_ -> fun ~random:_random__029_ -> E)))
         and _pair__025_ =
           (1.,
            (Base_quickcheck.Generator.create
               (fun ~size ~random ->
                  let _size__021_ = size in
                  let adjusted_size = Base.Int.pred _size__021_ in
                  Base_quickcheck.Generator.generate
                    (Base_quickcheck.Generator.create
                       (fun ~size:_size__026_ ->
                          fun ~random:_random__027_ ->
                            T
                              ((Base_quickcheck.Generator.generate
                                  quickcheck_generator_color
                                  ~size:_size__026_
                                  ~random:_random__027_),
                               (Base_quickcheck.Generator.generate
                                  quickcheck_generator_tree
                                  ~size:_size__026_
                                  ~random:_random__027_),
                                (Base_quickcheck.Generator.generate
                                  (Base_quickcheck.Generator.create
                                     (fun ~size:_size__026_ ~random:_random__027_ ->
                                        Splittable_random.int _random__027_ ~lo:0 ~hi:127))
                                  ~size:_size__026_
                                  ~random:_random__027_),
                                (Base_quickcheck.Generator.generate
                                  (Base_quickcheck.Generator.create
                                     (fun ~size:_size__026_ ~random:_random__027_ ->
                                        Splittable_random.int _random__027_ ~lo:0 ~hi:127))
                                  ~size:_size__026_
                                  ~random:_random__027_),
                               (Base_quickcheck.Generator.generate
                                  quickcheck_generator_tree
                                  ~size:_size__026_
                                  ~random:_random__027_))))
                    ~size:adjusted_size ~random)))
         in
         let rng = Base_quickcheck.Generator.create (
           fun ~size:_size_0__11_ ->
             fun ~random:_random__012_ ->
               Splittable_random.float _random__012_ ~lo:0. ~hi:0.2) in
         let _, _gen__022_ = _pair__024_ in
         let _, _gen__020_ = _pair__025_ in
         let _gen__023_ =
           Base_quickcheck.Generator.create (fun ~size ~random ->
             let float_value =
               Base_quickcheck.Generator.generate rng ~size ~random
             in
             if Float.(>=) float_value 0.1 then
               Base_quickcheck.Generator.generate _gen__020_ ~size ~random
             else
               Base_quickcheck.Generator.generate _gen__022_ ~size ~random)
         in
         Base_quickcheck.Generator.create (fun ~size ~random ->
           match size with
           | 0 -> Base_quickcheck.Generator.generate _gen__022_ ~size ~random
           | _ -> Base_quickcheck.Generator.generate _gen__023_ ~size ~random)) in
    Base_quickcheck.Generator.of_lazy quickcheck_generator_tree
end