(* open Core;; *)
(* open Core_bench;; *)
open Splittable_random;;
(* 
module F (G : Fast_gen.Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = 
      recursive (lift ()) (
        fun r _ ->
          bind size ~f:(fun cs ->
          choose [
            (lift 1., return (lift []));
            (i2f cs ,
              bind (int ~lo:(lift 0) ~hi:cs) ~f:(fun x ->
                bind (with_size ~size_c:(pred cs) @@ recurse r (lift ())) ~f:(fun xs ->
                  return (cons x xs)
                )
              )
            );
          ]
        )
      )

end

module BQ = F(Fast_gen.Bq_generator)
module SG = F(Fast_gen.Staged_generator)

let bq_gen = BQ.gen
let st_gen = Fast_gen.Staged_generator.jit SG.gen
let () = Fast_gen.Staged_generator.print SG.gen

let sizes = [10;50;100;1000;10000]

let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 50) ())
  [
  Bench.Test.create_indexed ~name:"BQ" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.State.create (Random.State.make_self_init ()) in
    fun () -> Base_quickcheck.Generator.generate bq_gen ~random ~size:n
  );
  Bench.Test.create_indexed ~name:"ST" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.State.create (Random.State.make_self_init ()) in
    fun () -> Base_quickcheck.Generator.generate st_gen ~random ~size:n
  );
] *)