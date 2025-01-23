open Impl

module BaseTypeStaged : Base_quickcheck.Test.S with type t = rbt = struct
  type t = rbt [@@deriving sexp, quickcheck]

  let quickcheck_generator =
    let rec lazy_t () =
      Base_quickcheck.Generator.create (fun ~size ~random ->
          if size <= 1 then
            Impl.E
          else
            let x = Splittable_random.int random ~lo:0 ~hi:1 in
            if x == 1 then
              Impl.E
            else
              let x''1 = (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
              let x''2 = (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
              let is_r_case = Splittable_random.bool random in
              let subtree_size = size - 1 in
              let left_subtree = Base_quickcheck.Generator.generate ~size:subtree_size ~random (lazy_t ()) in
              let right_subtree = Base_quickcheck.Generator.generate ~size:subtree_size ~random (lazy_t ()) in
              if is_r_case then
                Impl.T (Impl.R, left_subtree, x''1, x''2, right_subtree)
              else
                Impl.T (Impl.B, left_subtree, x''1, x''2, right_subtree))
    in
    lazy_t ()  
end

(*
let quickcheck_generator_tree =
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
           (Base_quickcheck.Generator.bind Base_quickcheck.Generator.size
              ~f:(fun _size__021_ ->
                    Base_quickcheck.Generator.with_size
                      ~size:(Base.Int.pred _size__021_)
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
                                     Nat.quickcheck_generator
                                     ~size:_size__026_
                                     ~random:_random__027_),
                                  (Base_quickcheck.Generator.generate
                                     Nat.quickcheck_generator
                                     ~size:_size__026_
                                     ~random:_random__027_),
                                  (Base_quickcheck.Generator.generate
                                     quickcheck_generator_tree
                                     ~size:_size__026_
                                     ~random:_random__027_))))))) in
       let _gen__022_ =
         Base_quickcheck.Generator.weighted_union [_pair__024_]
       and _gen__023_ =
         Base_quickcheck.Generator.weighted_union
           [_pair__024_; _pair__025_] in
       Base_quickcheck.Generator.bind Base_quickcheck.Generator.size
         ~f:(function | 0 -> _gen__022_ | _ -> _gen__023_)) in
  Base_quickcheck.Generator.of_lazy quickcheck_generator_tree
*)