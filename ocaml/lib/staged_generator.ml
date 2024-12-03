open Core;;

open Codegen.Let_syntax;;

type 'a t = RandGen of (size_c:(int Code.t) -> random_c:(Splittable_random.State.t Code.t) -> 'a Codegen.t)

type 'a recgen = (unit -> 'a Core.Quickcheck.Generator.t) Code.t

let return x = RandGen (fun ~size_c:_ ~random_c:_ -> Codegen.return x)
let bind (RandGen r) ~f = RandGen (fun ~size_c ~random_c ->
  let%bind a = r ~size_c ~random_c in
  let (RandGen r') = f a in
  r' ~size_c ~random_c
)



exception Unimplemented

(* doing nary choice is going to be funny... they build an array and binary search it to find the element.
We're proably gonna have to do it with some kind of static sorter, hardware style!
*)
let choose ((w1,(RandGen g1)) : int Code.t * 'a t) ((w2,(RandGen g2)) : int Code.t * 'a t) : 'a t = RandGen (
  fun ~size_c ~random_c ->
    let%bind sum = Codegen.gen_let [%code [%e w1] + [%e w2]] in
    let%bind w1w2_min = Codegen.gen_let [%code min [%e w1] [%e w2]] in 
    let%bind w1w2_max = Codegen.gen_let [%code max [%e w1] [%e w2]] in 
    let%bind rand = Codegen.gen_let [%code Splittable_random.int [%e random_c ] ~lo:[%e w1w2_min] ~hi:[%e w1w2_max] ] in
    Codegen.gen_if [%code [%e w1] < [%e w2]]
      ~tt:(
        Codegen.gen_if [%code [%e rand] < [%e w1]] ~tt:(g1 ~size_c ~random_c) ~ff:(g2 ~size_c ~random_c)
      )
      ~ff:(
        Codegen.gen_if [%code [%e rand] < [%e w2]] ~tt:(g2 ~size_c ~random_c) ~ff:(g1 ~size_c ~random_c)
      )
)

let with_size (RandGen f) ~size_c =
  RandGen (fun ~size_c:_ ~random_c -> f ~size_c:size_c ~random_c)

let size = RandGen (fun ~size_c ~random_c:_ -> Codegen.return size_c)

let gen_if b (RandGen f) (RandGen g) = RandGen (
  fun ~size_c  ~random_c ->
    Codegen.gen_if b ~tt:(f ~size_c ~random_c) ~ff:(g ~size_c ~random_c)
)

(* module Let_syntax = For_monad.Let_syntax *)

let recurse (gc : 'a recgen) : 'a Code.t t = RandGen (fun ~size_c ~random_c -> Codegen.return [%code 
  Core.Quickcheck.Generator.generate ~size:[%e size_c] ~random:[%e random_c] ([%e gc] ())
])

(*
let of_lazy lazy_t = create (fun ~size ~random -> generate (force lazy_t) ~size ~random)
*)
(* let fixed_point of_generator = *)
  (* let rec lazy_t = lazy (of_generator (of_lazy lazy_t)) in *)
  (* force lazy_t *)
(* ;; *)

let recursive (f : 'a recgen -> ('a Code.t) t) : ('a Base_quickcheck.Generator.t) Code.t =
  [%code
    let rec lazy_t () = Base_quickcheck.Generator.create (fun ~size ~random ->
      [%e let (RandGen r) = (f [%code lazy_t]) in
        Codegen.code_generate (r ~size_c:[%code size] ~random_c:[%code random])
      ]
    )
    in
    lazy_t ()
  ]

let to_qc (sg : ('a Code.t) t) : ('a Base_quickcheck.Generator.t) Code.t =
  let (RandGen f) = sg in
  [%code
    Base_quickcheck.Generator.create (fun ~size ~random ->
      [%e Codegen.code_generate (f ~size_c:[%code size] ~random_c:[%code random]) ]
    )
  ]


module For_monad = Monad.Make (struct
    type nonrec 'a t = 'a t

    let return = return
    let bind = bind
    let map = `Define_using_bind
  end)

let join = For_monad.join
let ignore_m = For_monad.ignore_m

let map = For_monad.map

let all_unit = For_monad.all_unit
let all = For_monad.all


module Monad_infix = For_monad.Monad_infix
include Monad_infix
module Let_syntax = For_monad.Let_syntax