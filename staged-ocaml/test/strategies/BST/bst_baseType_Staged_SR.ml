open Util.Limits
open Type;;

module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)

  type t = tree [@@deriving sexp, quickcheck]
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
                                      (Nat.staged_quickcheck_generator_sr_t (G.C.lift 100))
                                      ~f:(fun _x__007_ ->
                                            G.bind
                                              (Nat.staged_quickcheck_generator_sr_t (G.C.lift 100))
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

  let make_quickcheck_generator () =
    G.jit ~extra_cmi_paths:["/home/jcutler/Documents/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte"; "/home/jcutler/Documents/waffle-house/staged-ocaml/_build/default/test/strategies/BST/.BST.objs/byte"] staged_code

  let quickcheck_generator = make_quickcheck_generator ()

  let sexp_of_t = sexp_of_t