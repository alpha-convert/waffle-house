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
end
