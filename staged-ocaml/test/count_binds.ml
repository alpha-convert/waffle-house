module G = Fast_gen.Bq_generator


(* returns the average number of binds per trial *)
let run ~size ~num_trials name g =
  let rec go acc_binds k = 
    if k == 0 then (Int.to_float acc_binds /. Int.to_float num_trials)
    else
      (
        G.reset_bind_count();
        let random = Splittable_random.State.create (Base.Random.State.make_self_init ()) in
        ignore(Base_quickcheck.Generator.generate g ~size:size ~random:random);
        let n = G.get_num_binds() in
        go (n + acc_binds) (k-1)
      )
  in
  let n = go 0 num_trials in
  print_endline ("average number of binds in " ^ name ^ ": " ^ Float .to_string n)

let run_all ~named_gens ~size ~num_trials =
  Base.List.iter named_gens ~f:(fun (name,g) -> run name ~size ~num_trials g)