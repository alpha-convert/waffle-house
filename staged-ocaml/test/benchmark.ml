open Core;;
open Core_bench;;

let cartesian l l' = 
  List.concat (List.map ~f:(fun e -> List.map ~f:(fun e' -> (e,e')) l') l)

let bm ~bench_name ~named_gens ~(sizes : int list) ~quota ~seeds =
  Bench.bench
  ~run_config:(Bench.Run_config.create ~quota ())
  @@
  List.map named_gens ~f:(fun (gen_name,g) ->
    Bench.Test.create_parameterised ~name:(bench_name ^ "_" ^ gen_name) ~args:(List.map ~f:(fun (sz,sd) -> ("n=" ^ Int.to_string sz ^ ",r=" ^ Int.to_string sd,(sz,sd))) @@ cartesian sizes seeds) @@
      fun (size,seed) ->
        let random = Splittable_random.State.of_int seed in
        Staged.stage @@ fun () ->
          ignore (Base_quickcheck.Generator.generate g ~size:size ~random:random);
  )

let bm_nondet ~bench_name ~named_gens ~(sizes : int list) ~quota =
  Bench.bench
  ~run_config:(Bench.Run_config.create ~quota:quota ())
  @@
  List.map named_gens ~f:(fun (gen_name,g) ->
    Bench.Test.create_parameterised ~name:(bench_name ^ "_" ^ gen_name) ~args:(List.map ~f:(fun sz -> ("n=" ^ Int.to_string sz,sz)) sizes) @@
      fun size ->
        let random = Splittable_random.State.create (Random.State.make_self_init ()) in
        Staged.stage @@ fun () ->
          ignore (Base_quickcheck.Generator.generate g ~size:size ~random:random);
  )

