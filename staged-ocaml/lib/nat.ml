include Core

(* Define the type of natural numbers as an alias for Core.Int.t *)
type t = Core.Int.t [@@deriving sexp, quickcheck]

(* QuickCheck generator for natural numbers modulo 128
let quickcheck_generator = 
  RandGen (fun ~size_c:_ ~random_c ->
    Codegen.gen_let [%code 
      (Base_quickcheck.Generator.int |> Core.Quickcheck.Generator.generate ~size:10 ~random:[%e random_c]) mod 128
    ]
  )
*)

(*
let quickcheck_generator =
  Base_quickcheck.Generator.create (fun ~size:_ ~random ->
    let number = Splittable_random.int random ~lo:0 ~hi:127 in
    number
  )
*)

let quickcheck_generator =
  Base_quickcheck.Generator.bind
    (Base_quickcheck.Generator.create (fun ~size:_ ~random ->
       Splittable_random.int random ~lo:Int.min_value ~hi:Int.max_value))
    (fun number ->
      Base_quickcheck.Generator.return (number mod 128))

(* QuickCheck shrinker: no shrinking logic for simplicity *)
let quickcheck_shrinker =
  Base_quickcheck.Shrinker.create (fun _ -> Base.Sequence.empty)

(* QuickCheck observer: use the default observer for integers *)
let quickcheck_observer =
  Base_quickcheck.Observer.int
