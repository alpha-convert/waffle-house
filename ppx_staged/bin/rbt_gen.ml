open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Rbt;;
open Sexplib;;
open Sexplib0.Sexp_conv;;
open Base;;

module C_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)
let staged_quickcheck_generator_color =
  C_SR.weighted_union
    [((.< 1.  >.), (C_SR.return (.< R  >.)));
    ((.< 1.  >.), (C_SR.return (.< B  >.)))]
    
    let staged_quickcheck_generator =
      C_SR.recursive (C_SR.C.lift ())
        (fun go ->
           fun _ ->
             let _pair__015_ =
               ((.< 1.  >.), (C_SR.return (.< E  >.)))
             and _pair__016_ =
               ((.< 1.  >.),
                 (C_SR.bind C_SR.size
                    ~f:(fun _size__012_ ->
                          C_SR.with_size
                            ~size_c:(C_SR.C.pred _size__012_)
                            (C_SR.bind
                               (C_SR.recurse go (C_SR.C.lift ()))
                               ~f:(fun _x__019_ ->
                                     C_SR.bind
                                       (C_SR.bind C_SR.int
                                          ~f:(fun _i__018_ ->
                                                C_SR.return
                                                  (C_SR.C.modulus
                                                     _i__018_ 1000)))
                                       ~f:(fun _x__020_ ->
                                             C_SR.bind
                                               (C_SR.bind C_SR.int
                                                  ~f:(fun _i__017_ ->
                                                        C_SR.return
                                                          (C_SR.C.modulus
                                                            _i__017_
                                                            1000)))
                                               ~f:(fun _x__021_ ->
                                                     C_SR.bind
                                                       (C_SR.recurse
                                                          go
                                                          (C_SR.C.lift
                                                            ()))
                                                       ~f:(fun
                                                            _x__022_
                                                            ->
                                                            C_SR.bind
                                                            staged_quickcheck_generator_color
                                                            ~f:(
                                                            fun
                                                            _x__023_
                                                            ->
                                                            C_SR.return
                                                            (.<
                                                            T
                                                            ((.~_x__023_),
                                                            (.~_x__022_),
                                                            (.~_x__021_),
                                                            (.~_x__020_),
                                                            (.~_x__019_)) 
                                                            >.)))))))))) in
             let _gen__013_ = C_SR.weighted_union [_pair__015_]
             and _gen__014_ =
               C_SR.weighted_union [_pair__015_; _pair__016_] in
             C_SR.bind C_SR.size
               ~f:(fun x -> C_SR.if_z x _gen__013_ _gen__014_))