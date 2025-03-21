open Type_defn;;
open Fast_gen;;
open Core;;
open Core_unix;;

module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)

type t = Type_defn.expr [@@deriving quickcheck, sexp]
let staged_quickcheck_generator_typ =
  G.recursive (G.C.lift ())
    (fun go ->
       fun _ ->
         let _pair__004_ =
           ((.< 1.  >.), (G.return (.< TBool  >.)))
         and _pair__005_ =
           ((.< 1.  >.),
             (G.bind G.size
                ~f:(fun _size__001_ ->
                      G.with_size ~size_c:(G.C.pred _size__001_)
                        (G.bind (G.recurse go (G.C.lift ()))
                           ~f:(fun _x__006_ ->
                                 G.bind
                                   (G.recurse go (G.C.lift ()))
                                   ~f:(fun _x__007_ ->
                                         G.return
                                           (.<
                                              TFun
                                                ((.~_x__007_),
                                                  (.~_x__006_)) 
                                              >.))))))) in
         let _gen__002_ = G.weighted_union [_pair__004_]
         and _gen__003_ =
           G.weighted_union [_pair__004_; _pair__005_] in
         G.bind G.size
           ~f:(fun x -> G.if_z x _gen__002_ _gen__003_))
let staged_code =
    G.recursive (G.C.lift ())
      (fun go ->
         fun _ ->
           let _pair__042_ =
             ((.< 1.  >.),
               (G.bind G.int
                  ~f:(fun _x__050_ ->
                        G.return (.< Var (.~_x__050_)  >.))))
           and _pair__043_ =
             ((.< 1.  >.),
               (G.bind G.bool
                  ~f:(fun _x__051_ ->
                        G.return (.< Bool (.~_x__051_)  >.))))
           and _pair__044_ =
             ((.< 1.  >.),
               (G.bind G.size
                  ~f:(fun _size__039_ ->
                        G.with_size ~size_c:(G.C.pred _size__039_)
                          (G.bind (G.recurse go (G.C.lift ()))
                             ~f:(fun _x__046_ ->
                                   G.bind
                                     staged_quickcheck_generator_typ
                                     ~f:(fun _x__047_ ->
                                           G.return
                                             (.<
                                                Abs
                                                  ((.~_x__047_),
                                                    (.~_x__046_)) 
                                                >.)))))))
           and _pair__045_ =
             ((.< 1.  >.),
               (G.bind G.size
                  ~f:(fun _size__039_ ->
                        G.with_size ~size_c:(G.C.pred _size__039_)
                          (G.bind (G.recurse go (G.C.lift ()))
                             ~f:(fun _x__048_ ->
                                   G.bind
                                     (G.recurse go (G.C.lift ()))
                                     ~f:(fun _x__049_ ->
                                           G.return
                                             (.<
                                                App
                                                  ((.~_x__049_),
                                                    (.~_x__048_)) 
                                                >.))))))) in
           let _gen__040_ =
             G.weighted_union [_pair__042_; _pair__043_]
           and _gen__041_ =
             G.weighted_union
               [_pair__042_; _pair__043_; _pair__044_; _pair__045_] in
           G.bind G.size
             ~f:(fun x -> G.if_z x _gen__040_ _gen__041_))
let quickcheck_generator = G.jit ~extra_cmi_paths:["/home/ubuntu/etna2/workloads/OCaml/STLC/_build/default/lib/.STLC.objs/byte"] staged_code
let sexp_of_t = sexp_of_t