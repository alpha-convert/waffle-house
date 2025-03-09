open Core;;
open Core_bench;;

let cartesian l l' = 
  List.concat (List.map ~f:(fun e -> List.map ~f:(fun e' -> (e,e')) l') l)

let bm ~bench_name ~named_gens ~(sizes : int list) ~num_calls ~seeds = Bench.bench
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls num_calls) ())
  @@
  List.map named_gens ~f:(fun (gen_name,g) ->
    Bench.Test.create_parameterised ~name:(bench_name ^ "_" ^ gen_name) ~args:(List.map ~f:(fun (sz,sd) -> ("n=" ^ Int.to_string sz ^ ",r=" ^ Int.to_string sd,(sz,sd))) @@ cartesian sizes seeds) @@
      fun (size,seed) ->
        let random = Splittable_random.State.of_int seed in
        let min_dur = Magic_trace.Min_duration.of_ns 3_000 in
        Staged.stage @@ fun () ->
          Magic_trace.mark_start ();
          ignore (Base_quickcheck.Generator.generate g ~size:size ~random:random);
          if Magic_trace.Min_duration.over min_dur then Magic_trace.take_snapshot ()
  )