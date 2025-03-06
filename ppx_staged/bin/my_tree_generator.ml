open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open My_tree;;
open Sexplib;;
module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
open Sexplib0.Sexp_conv;;

let quickcheck_generator =
  G_SR.recursive (G_SR.C.lift ())
    (fun go ->
       fun _ ->
         let _pair__004_ =
           ((.< 1.  >.),
             (G_SR.bind
                (G_SR.int ~lo:(G_SR.C.lift 0)
                   ~hi:(G_SR.C.lift 100))
                ~f:(fun _x__009_ ->
                      G_SR.return (.< Leaf (.~_x__009_)  >.))))
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
                                         G_SR.bind
                                           (G_SR.int
                                              ~lo:(G_SR.C.lift 0)
                                              ~hi:(G_SR.C.lift
                                                     100))
                                           ~f:(fun _x__008_ ->
                                                 G_SR.return
                                                   (.<
                                                      Node
                                                        ((.~_x__006_),
                                                        (.~_x__007_),
                                                        (.~_x__008_)) 
                                                      >.)))))))) in
         let _gen__002_ = G_SR.weighted_union [_pair__004_]
         and _gen__003_ =
           G_SR.weighted_union [_pair__004_; _pair__005_] in
         G_SR.bind G_SR.size
           ~f:(fun x -> G_SR.if_z x _gen__002_ _gen__003_))

let rec sexp_of_t =
  (function
   | My_tree.Leaf arg0__019_ ->
       let res0__020_ = sexp_of_int arg0__019_ in
       Sexplib0.Sexp.List [Sexplib0.Sexp.Atom "Leaf"; res0__020_]
   | My_tree.Node (arg0__021_, arg1__022_, arg2__023_) ->
       let res0__024_ = sexp_of_int arg0__021_
       and res1__025_ = sexp_of_t arg1__022_
       and res2__026_ = sexp_of_int arg2__023_ in
       Sexplib0.Sexp.List
         [Sexplib0.Sexp.Atom "Node"; res0__024_; res1__025_; res2__026_] : 
  t -> Sexplib0.Sexp.t)
