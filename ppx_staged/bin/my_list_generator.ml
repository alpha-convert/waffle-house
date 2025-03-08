open Stdio
open Fast_gen;;
open My_list;;
module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)

let staged_quickcheck_generator =
  G_SR.recursive (G_SR.C.lift ())
    (fun go ->
       fun _ ->
         let _pair__004_ =
           ((.< 1.  >.), (G_SR.return (.< Empty  >.)))
         and _pair__005_ =
           ((.< 10000.  >.),
             (G_SR.bind G_SR.size
                ~f:(fun _size__001_ ->
                      G_SR.with_size
                        ~size_c:(G_SR.C.pred _size__001_)
                        (G_SR.bind
                           (G_SR.recurse go (G_SR.C.lift ()))
                           ~f:(fun _x__006_ ->
                                 G_SR.bind G_SR.bool
                                   ~f:(fun _x__007_ ->
                                         G_SR.return
                                           (.<
                                              Cons
                                                ((.~_x__007_),
                                                  (.~_x__006_)) 
                                              >.))))))) in
         let _gen__002_ = G_SR.weighted_union [_pair__004_]
         and _gen__003_ =
           G_SR.weighted_union [_pair__004_; _pair__005_] in
         G_SR.bind G_SR.size
           ~f:(fun x -> G_SR.if_z x _gen__002_ _gen__003_))