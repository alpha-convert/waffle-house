open Util.Limits
open Type;;
open Fast_gen;;
open Core;;

module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_random)

  type t = Type.tree [@@deriving sexp, quickcheck]

  let staged_code =
    G.recursive (G.C.lift ())
      (fun go ->
          fun _ ->
            let _pair__004_ = ((.< 1.  >.), (G.return (.< E  >.)))
            and _pair__005_ =
              ((.< 1.  >.),
                (G.bind G.size
                  ~f:(fun _size__001_ ->
                        G.with_size ~size_c:(G.C.pred _size__001_)
                          (G.bind (G.recurse go (G.C.lift ()))
                              ~f:(fun _x__006_ ->
                                    G.bind
                                      (Nat.staged_quickcheck_generator_c_t (G.C.lift bst_type_limits))
                                      ~f:(fun _x__007_ ->
                                            G.bind
                                              (Nat.staged_quickcheck_generator_c_t (G.C.lift bst_type_limits))
                                              ~f:(fun _x__008_ ->
                                                    G.bind
                                                      (G.recurse go
                                                        (G.C.lift
                                                          ()))
                                                      ~f:(fun
                                                          _x__009_
                                                          ->
                                                          G.return
                                                          (.<
                                                          T
                                                          ((.~_x__009_),
                                                          (.~_x__008_),
                                                          (.~_x__007_),
                                                          (.~_x__006_)) 
                                                          >.))))))))) in
            let _gen__002_ = G.weighted_union [_pair__004_]
            and _gen__003_ =
              G.weighted_union [_pair__004_; _pair__005_] in
            G.bind G.size
              ~f:(fun x -> G.if_z x _gen__002_ _gen__003_))

  let quickcheck_generator = 
    G.jit ~extra_cmi_paths:["/home/ubuntu/etna2/workloads/OCaml/BST/_build/default/lib/.BST.objs/byte"] staged_code
  
  let sexp_of_t = sexp_of_t