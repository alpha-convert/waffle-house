open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open My_variant;;
open Sexplib;;
open Sexplib0;;
open Sexplib0.Sexp_conv;;
module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)

let quickcheck_generator =
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

let sexp_of_t =
(function
  | MyInt arg0__056_ ->
      let res0__057_ = sexp_of_int arg0__056_ in
      Sexplib0.Sexp.List [Sexplib0.Sexp.Atom "MyInt"; res0__057_]
  | MyFloat (arg0__062_, arg1__063_) ->
      let res0__064_ =
        let (arg0__058_, arg1__059_) = arg0__062_ in
        let res0__060_ = sexp_of_float arg0__058_
        and res1__061_ = sexp_of_bool arg1__059_ in
        Sexplib0.Sexp.List [res0__060_; res1__061_]
      and res1__065_ = sexp_of_int arg1__063_ in
      Sexplib0.Sexp.List
        [Sexplib0.Sexp.Atom "MyFloat"; res0__064_; res1__065_]
  | MyPair (arg0__066_, arg1__067_) ->
      let res0__068_ = sexp_of_int arg0__066_
      and res1__069_ = sexp_of_float arg1__067_ in
      Sexplib0.Sexp.List
        [Sexplib0.Sexp.Atom "MyPair"; res0__068_; res1__069_] : 
t -> Sexplib0.Sexp.t)