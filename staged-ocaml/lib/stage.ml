open Core 
open Custom;;
module Stage = struct
  type t = Custom.custom_list

  let quickcheck_generator =
    let rec quickcheck_generator_custom_list =
      lazy
        (let quickcheck_generator_custom_list =
           Base_quickcheck.Generator.of_lazy
             quickcheck_generator_custom_list in
         let _pair__011_ =
           (1.,
            (Base_quickcheck.Generator.create
               (fun ~size:_size__015_ ~random:_random__016_ -> Nil)))
         and _pair__012_ =
           (1.,
            (Base_quickcheck.Generator.create
               (fun ~size ~random ->
                 match size with
                 | 0 -> Nil
                 | _ ->
                     Cons
                       (Splittable_random.bool random,
                        Base_quickcheck.Generator.generate
                          quickcheck_generator_custom_list
                          ~size:(Base.Int.pred size)
                          ~random)))) in
         let rng = Base_quickcheck.Generator.create (
           fun ~size:_size_0__11_ ->
             fun ~random:_random__012_ ->
               Splittable_random.float _random__012_ ~lo:0. ~hi:0.2) in
         let _, sndd = _pair__012_ in
         let _, _gen__009_ = _pair__011_ in
         let _gen__010_ =
          Base_quickcheck.Generator.create (fun ~size ~random ->
            let float_value =
              Base_quickcheck.Generator.generate rng ~size ~random
            in
            if Float.(>=) float_value 0.1 then
              Base_quickcheck.Generator.generate sndd ~size ~random
            else
              Base_quickcheck.Generator.generate _gen__009_ ~size ~random) in
         Base_quickcheck.Generator.create (fun ~size ~random ->
           match size with
           | 0 -> Base_quickcheck.Generator.generate _gen__009_ ~size ~random
           | _ -> Base_quickcheck.Generator.generate _gen__010_ ~size ~random)) in
    Base_quickcheck.Generator.of_lazy quickcheck_generator_custom_list
  
(*
  let quickcheck_generator =
    let rec quickcheck_generator_custom_list =
      lazy
        (let quickcheck_generator_custom_list =
            Base_quickcheck.Generator.of_lazy
              quickcheck_generator_custom_list in
          let _pair__011_ =
            (1.,
              (Base_quickcheck.Generator.create
                (fun ~size:_size__015_ -> fun ~random:_random__016_ -> Nil)))
          and _pair__012_ =
            (1.,
              (Base_quickcheck.Generator.bind Base_quickcheck.Generator.size
                ~f:(fun _size__008_ ->
                      Base_quickcheck.Generator.with_size
                        ~size:(Base.Int.pred _size__008_)
                        (Base_quickcheck.Generator.create
                            (fun ~size:_size__013_ ->
                              fun ~random:_random__014_ ->
                                Cons
                                  ((Base_quickcheck.Generator.generate
                                      quickcheck_generator_bool
                                      ~size:_size__013_
                                      ~random:_random__014_),
                                    (Base_quickcheck.Generator.generate
                                        quickcheck_generator_custom_list
                                        ~size:_size__013_
                                        ~random:_random__014_))))))) in
          let _gen__009_ =
            Base_quickcheck.Generator.weighted_union [_pair__011_]
          and _gen__010_ =
            Base_quickcheck.Generator.weighted_union
              [_pair__011_; _pair__012_] in
          Base_quickcheck.Generator.bind Base_quickcheck.Generator.size
            ~f:(function | 0 -> _gen__009_ | _ -> _gen__010_)) in
    Base_quickcheck.Generator.of_lazy quickcheck_generator_custom_list  
*)
end
