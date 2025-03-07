open Core;;
open Core_bench;;

let bm ~bench_name ~named_gens ~sizes ~num_calls = Bench.bench
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls num_calls) ())
  @@
  List.map named_gens ~f:(fun (gen_name,g) ->
    Bench.Test.create_indexed ~name:(bench_name ^ "_" ^ gen_name) ~args:sizes @@
      fun n ->
        let u = Random.State.make_self_init () in
        let s = Splittable_random.State.of_int (Random.State.int u Int.max_value) in
        Staged.stage @@ fun () -> Base_quickcheck.Generator.generate g ~size:n ~random:s
  )