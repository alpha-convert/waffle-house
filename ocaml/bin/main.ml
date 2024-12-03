open Core;;
open Fast_gen;;

open Core_bench;;

let () =
  Format.printf "[@[%a@]]@." Ppx_stage.print (Staged_treegen.gc)

let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
  [
  Bench.Test.create_indexed ~name:"gentree" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Basicgen.gen
  );
  Bench.Test.create_indexed ~name:"gen-manual-unfold" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Fastgen.gen_total
  );
  (* (let sg = Ppx_stage.run (Staged_treegen.gc) in
  Bench.Test.create_indexed ~name:"gen-staged" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n sg
  )); *)
  Bench.Test.create_indexed ~name:"gen-staged-splat" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Staged_treegen.splat
  );
]