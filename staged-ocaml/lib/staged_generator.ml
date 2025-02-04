open Core;;
open Codelib;;
open Codecps;;
open Codecps.Let_syntax;;

type 'a t = { rand_gen : size_c:(int code) -> random_c:(Splittable_random.State.t code) -> 'a code Codecps.t }

(* type 'a recgen = (unit -> 'a Core.Quickcheck.Generator.t) code *)

let return x = { rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.return x }

let bind (r : 'a t) ~(f : 'a code -> 'b t) = { rand_gen = fun ~size_c ~random_c ->
  (* need to figure out how to letinsert here! *)
  let%bind a = r.rand_gen ~size_c ~random_c in
  let%bind a = Codecps.let_insert a in
  (f (v2c a)).rand_gen ~size_c ~random_c
}

let bool : bool t = {
  rand_gen =
    fun ~size_c:_ ~random_c ->
      Codecps.return .< Splittable_random.bool .~random_c >.
}

let int ~(lo : int code) ~(hi : int code) : int t = {
  rand_gen =
    fun ~size_c:_ ~random_c ->
      Codecps.return .< Splittable_random.int ~lo:.~lo ~hi:.~hi .~random_c >.
}

let rec genpick (n : int val_code) (ws : (int val_code * 'a t) list) : 'a t =
  match ws with
  | [] -> return .< failwith "Fell of the end of pick list" >.
  | (k,g) :: ws' ->
        { rand_gen = 
          fun ~size_c ~random_c ->
          let%bind leq = Codecps.split_bool .< .~(v2c n) < .~(v2c k) >. in
          if leq then
            g.rand_gen ~size_c ~random_c
          else
            let%bind n' = Codecps.let_insert .< .~(v2c n) - .~(v2c k) >. in
            (genpick n' ws').rand_gen ~size_c ~random_c
        }

  
let histsum (ws : (int val_code * 'a t) list) : ((int val_code * 'a t) list * int val_code) Codecps.t =
    let rec go (ws : (int val_code * 'a t) list) (acc : int val_code) : ((int val_code * 'a t) list * int val_code) Codecps.t =
      match ws with
      | [] -> Codecps.return ([],acc)
      | (cn,g) :: ws' ->
          let%bind acc' = Codecps.let_insert .< .~(v2c acc) + .~(v2c cn) >. in
          let%bind (hist,sum) = go ws' acc' in
          Codecps.return ((acc',g) :: hist, sum)
      in
    let%bind zero = let_insert .<0>. in
    go ws zero

let choose (ws : (int code * 'a t) list) : 'a t =
  { rand_gen = fun ~size_c ~random_c ->
      let%bind ws' = Codecps.all @@ List.map ~f:(fun (cn,g) -> let%bind cvn = Codecps.let_insert cn in Codecps.return (cvn,g)) ws in
      let%bind (hist,sum) = histsum ws' in
      let%bind n = (int ~lo:.<0>. ~hi:(v2c sum)).rand_gen ~size_c ~random_c in
      let%bind n = Codecps.let_insert n in
      (genpick n hist).rand_gen ~size_c ~random_c
  }

(*

(* exception Unimplemented *)

(* doing nary choice is going to be funny... they build an array and binary search it to find the element.
We're proably gonna have to do it with some kind of static sorter, hardware style!
*)
let choose ((w1,(RandGen g1)) : int Code.t * 'a t) ((w2,(RandGen g2)) : int Code.t * 'a t) : 'a t = RandGen (
  fun ~size_c ~random_c ->
    let%bind rand = Codecps.gen_let [%code Splittable_random.int [%e random_c] ~lo:0 ~hi:([%e w1] + [%e w2]) ] in
    Codecps.gen_if [%code [%e rand] < [%e w1]] ~tt:(g1 ~size_c ~random_c) ~ff:(g2 ~size_c ~random_c)
)

let with_size (RandGen f) ~size_c =
  RandGen (fun ~size_c:_ ~random_c -> f ~size_c:size_c ~random_c)

let size = RandGen (fun ~size_c ~random_c:_ -> Codecps.return size_c)

let gen_if b (RandGen f) (RandGen g) = RandGen (
  fun ~size_c  ~random_c ->
    Codecps.gen_if b ~tt:(f ~size_c ~random_c) ~ff:(g ~size_c ~random_c)
)

(* module Let_syntax = For_monad.Let_syntax *)

let recurse (gc : 'a recgen) : 'a Code.t t = RandGen (fun ~size_c ~random_c -> Codecps.return [%code 
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
        Codecps.code_generate (r ~size_c:[%code size] ~random_c:[%code random])
      ]
    )
    in
    lazy_t ()
  ]

let to_qc (sg : ('a Code.t) t) : ('a Base_quickcheck.Generator.t) Code.t =
  let (RandGen f) = sg in
  [%code
    Base_quickcheck.Generator.create (fun ~size ~random ->
      [%e Codecps.code_generate (f ~size_c:[%code size] ~random_c:[%code random]) ]
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
*)