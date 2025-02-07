open Fast_gen;;
open Core;;

module type TestCase = sig
  type t [@@deriving eq, show]
  module F : functor (G : Generator_intf.GENERATOR) -> sig
    val gen : t G.t
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

module MakeDiffTest(T : TestCase) = struct
  module BQ_G = T.F(Bq_generator)
  module ST_G = T.F(Staged_generator)

  let bq_gen = BQ_G.gen
  let st_gen = Base_quickcheck.Generator.create (Staged_generator.jit ST_G.gen)
  let () = Staged_generator.print ST_G.gen

  exception Fail of T.t * T.t

  (* confusing thing that got me... Alcotest redirects std to file, so "noise"
  you print here won't show up in stdout. See _build/default/test/_build for the ouptut of your tests.*)
  let run ?config () =
    Base_quickcheck.Test.run_exn
     ?config:config
     ~f:(
      fun (size,seed) ->
        let v1 = Base_quickcheck.Generator.generate bq_gen ~size ~random:(Splittable_random.State.of_int seed) in
        let v2 = Base_quickcheck.Generator.generate st_gen ~size ~random:(Splittable_random.State.of_int seed) in
        if T.equal v1 v2 then print_endline ("Success: " ^ T.show v1) else raise (Fail (v1,v2))
     )
     (module SizeRand)

  let completes f () =
    try
      f (); ()
    with e -> Alcotest.fail (Exn.to_string e)

  (* here, quick means "always run this test "*)
  let alco ?config s = Alcotest.test_case s `Quick (completes (run ?config))
end