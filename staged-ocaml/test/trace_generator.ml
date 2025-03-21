module G = Fast_gen.Bq_generator


(* returns the average number of binds per trial *)
let run ~size ~num_trials name g =
  let rec go k = 
    if k == 0 then Magic_trace.take_snapshot ()
    else
      (
        let random = Splittable_random.State.create (Base.Random.State.make_self_init ()) in
        ignore(Base_quickcheck.Generator.generate g ~size:size ~random:random);
        go (k-1)
      )
  in
  go num_trials