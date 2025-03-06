open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open My_list;;

module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
(*
let quickcheck_generator_my_list =
  G_SR.recursive (G_SR.C.lift ()) (fun go _ -> 
    let _pair__007_ =
      ((.< 1.  >.), (G_SR.return (.< Empty  >.)))
    and _pair__008_ =
      ((.< 1.  >.),
        (G_SR.bind G_SR.size
            ~f:(fun _size__004_ ->
                  G_SR.with_size
                    ~size_c:(G_SR.C.pred _size__004_)
                    (G_SR.bind
                      (G_SR.int ~lo:(G_SR.C.lift 0)
                          ~hi:(G_SR.C.lift 100))
                      ~f:(fun _x__009_ ->
                            G_SR.bind
                              (G_SR.recurse go (G_SR.C.lift ()))
                              ~f:(fun _x__010_ ->
                                    G_SR.return
                                      (.<
                                          Cons
                                            (
                                              (.~_x__009_),
                                              (.~_x__010_)
                                            )
                                    >.)
                                    )
                                )
                              )
                            )
                          )
                        ) in
    let _gen__005_ = G_SR.weighted_union [_pair__007_]
    and _gen__006_ =
      G_SR.weighted_union [_pair__007_; _pair__008_] in
    G_SR.bind G_SR.size  ~f:(fun x -> G_SR.if_z x _gen__005_ _gen__006_)
  )
*)
let rec show = function
| Empty -> Printf.printf "\nEmpty\n"
| Cons (i, rest) -> 
    Printf.printf "\nCons (%d, _)\n" i;
    show rest
  
    let rec quickcheck_generator_my_list =
      G_SR.recursive (G_SR.C.lift ())
        (fun go ->
           fun _ ->
             let _pair__004_ =
               ((.< 1.  >.), (G_SR.return (.< Empty  >.)))
             and _pair__005_ =
               ((.< 1.  >.),
                 (G_SR.bind G_SR.size
                    ~f:(fun _size__001_ ->
                          G_SR.with_size
                            ~size_c:(G_SR.C.pred _size__001_)
                            (G_SR.bind
                               (G_SR.int ~lo:(G_SR.C.lift 0)
                                  ~hi:(G_SR.C.lift 100))
                               ~f:(fun _x__006_ ->
                                     G_SR.bind
                                       (G_SR.recurse go
                                          (G_SR.C.lift ()))
                                       ~f:(fun _x__007_ ->
                                             G_SR.return
                                               (.<
                                                  Cons
                                                    ((.~_x__006_),
                                                      (.~_x__007_)) 
                                                  >.))))))) in
             let _gen__002_ = G_SR.weighted_union [_pair__004_]
             and _gen__003_ =
               G_SR.weighted_union [_pair__004_; _pair__005_] in
             G_SR.bind G_SR.size
               ~f:(fun x -> G_SR.if_z x _gen__002_ _gen__003_))