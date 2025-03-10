open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open My_tree;;
open Sexplib;;
open Sexplib0.Sexp_conv;;
open Base;;

module C_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)

let staged_quickcheck_generator =
  C_SR.recursive (C_SR.C.lift ())
    (fun go ->
       fun _ ->
         let _pair__047_ =
           ((.< 1.  >.), (C_SR.return (.< E  >.)))
         and _pair__048_ =
           ((.< 1.  >.),
             (C_SR.bind C_SR.size
                ~f:(fun _size__044_ ->
                      C_SR.with_size
                        ~size_c:(C_SR.C.pred _size__044_)
                        (C_SR.bind
                           (C_SR.recurse go (C_SR.C.lift ()))
                           ~f:(fun _x__049_ ->
                                 C_SR.bind
                                   C_SR.int
                                   ~f:(fun _x__050_ ->
                                         C_SR.bind
                                           C_SR.int
                                           ~f:(fun _x__051_ ->
                                                 C_SR.bind
                                                   (C_SR.recurse
                                                      go
                                                      (C_SR.C.lift
                                                        ()))
                                                   ~f:(fun
                                                        _x__052_
                                                        ->
                                                        C_SR.return
                                                        (.<
                                                        T
                                                        ((.~_x__052_),
                                                        (.~_x__051_),
                                                        (.~_x__050_),
                                                        (.~_x__049_)) 
                                                        >.))))))))) in
         let _gen__045_ = C_SR.weighted_union [_pair__047_]
         and _gen__046_ =
           C_SR.weighted_union [_pair__047_; _pair__048_] in
         C_SR.bind C_SR.size
           ~f:(fun x -> C_SR.if_z x _gen__045_ _gen__046_))