open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Variant;;

module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)

let quickcheck_generator_variant =
  G_SR.weighted_union
    [((.< 1.  >.),
       (G_SR.bind
          (G_SR.int ~lo:(G_SR.C.lift 0) ~hi:(G_SR.C.lift 100))
          ~f:(fun _x__004_ -> G_SR.return (.< MyInt (.~_x__004_)  >.))));
    ((.< 1.  >.),
      (G_SR.bind
         (G_SR.bind
            (G_SR.float ~lo:(G_SR.C.lift 0.0) ~hi:(G_SR.C.lift 1.0))
            ~f:(fun _x__005_ ->
                  G_SR.bind G_SR.bool
                    ~f:(fun _x__006_ ->
                          G_SR.return
                            (.< ((.~_x__005_), (.~_x__006_))  >.))))
         ~f:(fun _x__007_ ->
               G_SR.bind
                 (G_SR.int ~lo:(G_SR.C.lift 0) ~hi:(G_SR.C.lift 100))
                 ~f:(fun _x__008_ ->
                       G_SR.return
                         (.< MyFloat ((.~_x__007_), (.~_x__008_))  >.)))));
    ((.< 1.  >.),
      (G_SR.bind (G_SR.int ~lo:(G_SR.C.lift 0) ~hi:(G_SR.C.lift 100))
         ~f:(fun _x__009_ ->
               G_SR.bind
                 (G_SR.float ~lo:(G_SR.C.lift 0.0)
                    ~hi:(G_SR.C.lift 1.0))
                 ~f:(fun _x__010_ ->
                       G_SR.return
                         (.< MyPair ((.~_x__009_), (.~_x__010_))  >.)))))]