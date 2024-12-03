open Core;;
open Fast_gen;;

  (* let of_lazy lazy_t = create (fun ~size ~random -> generate (force lazy_t) ~size ~random)
  let fixed_point of_generator =
    let rec lazy_t = lazy (of_generator (of_lazy lazy_t)) in
    force lazy_t
  ;; *)


(* let bind t ~f =
    create (fun ~size ~random ->
      let x = generate t ~size ~random in
      generate (f x) ~size ~random)
*)

open Core_bench;;

let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
  [
  Bench.Test.create_indexed ~name:"gentree" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Basicgen.gen
  );
  (* Bench.Test.create_indexed ~name:"gen-unfolded" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Fastgen.gen
  ); *)
  Bench.Test.create_indexed ~name:"gen-unfolded" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Fastgen.gen_total
  );
]