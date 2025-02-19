open Fast_gen;;
open Core;;

module type TestCase = sig
  type t [@@deriving eq, show]
  module F : functor (G : Generator_intf.S) -> sig
    val gen : t G.c G.t
  end
end

module SizeRand : Base_quickcheck.Test.S with type t = Int.t * Int.t = struct
  type t = Int.t * Int.t [@@deriving quickcheck, sexp_of]

  open Base_quickcheck.Generator;;
  let quickcheck_generator =
    bind small_strictly_positive_int ~f:(fun x ->
      bind Base_quickcheck.Generator.int ~f:(fun y->
        return (x,y)
      )
    )
end

let difftest ?config ~name:s exn eq g1 g2 = 
  let completes f () =
    try
      f (); ()
    with e -> Alcotest.fail (Exn.to_string e)
  in let dt () =
    Base_quickcheck.Test.run_exn
     ?config:config
     ~f:(
      fun (size,seed) ->
        let v1 = Base_quickcheck.Generator.generate g1 ~size ~random:(Splittable_random.State.of_int seed) in
        let v2 = Base_quickcheck.Generator.generate g2 ~size ~random:(Splittable_random.State.of_int seed) in
        if eq v1 v2 then () else exn v1 v2
     )
     (module SizeRand)
  in
    Alcotest.test_case s `Quick (completes dt)

module MakeDiffTest(T : TestCase)(G1:Generator_intf.S)(G2:Generator_intf.S) = struct
  module T1 = T.F(G1)
  module T2 = T.F(G2)

  let g1 = G1.jit T1.gen
  let g2 = G2.jit T2.gen

  exception Fail of T.t * T.t

  let alco ?config name = difftest ?config ~name (fun v1 v2 -> raise (Fail (v1,v2))) T.equal g1 g2
end