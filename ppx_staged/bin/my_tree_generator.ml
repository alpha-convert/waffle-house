open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open My_tree;;
open Sexplib;;
open Sexplib0.Sexp_conv;;
open Base;;

module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)

let staged_quickcheck_generator =
  G_SR.recursive (G_SR.C.lift ())
    (fun go ->
       fun _ ->
         let _pair__004_ =
           ((.< 1.  >.), (G_SR.return (.< E  >.)))
         and _pair__005_ =
           ((.< 1.  >.),
             (G_SR.bind G_SR.size
                ~f:(fun _size__001_ ->
                      G_SR.with_size
                        ~size_c:(G_SR.C.pred _size__001_)
                        (G_SR.bind
                           (G_SR.recurse go (G_SR.C.lift ()))
                           ~f:(fun _x__006_ ->
                                 G_SR.bind G_SR.int
                                   ~f:(fun _x__007_ ->
                                         G_SR.bind G_SR.int
                                           ~f:(fun _x__008_ ->
                                                 G_SR.bind
                                                   (G_SR.recurse
                                                      go
                                                      (G_SR.C.lift
                                                        ()))
                                                   ~f:(fun
                                                        _x__009_
                                                        ->
                                                        G_SR.return
                                                        (.<
                                                        T
                                                        ((.~_x__009_),
                                                        (.~_x__008_),
                                                        (.~_x__007_),
                                                        (.~_x__006_)) 
                                                        >.))))))))) in
         let _gen__002_ = G_SR.weighted_union [_pair__004_]
         and _gen__003_ =
           G_SR.weighted_union [_pair__004_; _pair__005_] in
         G_SR.bind G_SR.size
           ~f:(fun x -> G_SR.if_z x _gen__002_ _gen__003_))

let rec sexp_of_t =
      (function
       | E -> Sexplib0.Sexp.Atom "E"
       | T (arg0__025_, arg1__026_, arg2__027_, arg3__028_) ->
           let res0__029_ = sexp_of_t arg0__025_
           and res1__030_ = sexp_of_int arg1__026_
           and res2__031_ = sexp_of_int arg2__027_
           and res3__032_ = sexp_of_t arg3__028_ in
           Sexplib0.Sexp.List
             [Sexplib0.Sexp.Atom "T";
             res0__029_;
             res1__030_;
             res2__031_;
             res3__032_] : t -> Sexplib0.Sexp.t)