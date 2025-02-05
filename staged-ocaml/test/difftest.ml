open Fast_gen;;
open Core;;

module type TestCase = sig
  type t
  val eq : t -> t -> bool
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
  let st_gen = Staged_generator.jit ST_G.gen

  let run ?config () =
    Base_quickcheck.Test.run_exn
     ?config:config
     ~f:(
      fun (size,seed) ->
        let v1 = Base_quickcheck.Generator.generate bq_gen ~size ~random:(Splittable_random.State.of_int seed) in
        let v2 = Base_quickcheck.Generator.generate st_gen ~size ~random:(Splittable_random.State.of_int seed) in
        if T.eq v1 v2 then () else failwith "Failed!"
     )
     (module SizeRand)
end