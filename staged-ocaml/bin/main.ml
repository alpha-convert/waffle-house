open Core;;
open Fast_gen;;

open Core_bench;;

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


(* open Base_quickcheck.Generator;;
open Base_quickcheck.Generator.Let_syntax;;
open Core_bench;;

let gen_list_bool = fixed_point (
    fun gl ->
        let%bind n = size in
        if n <= 0 then return [] else
          let%bind xs = with_size ~size:(n-1) gl in
          let%bind x = bool in
          return (x :: xs)
)

let gen_list_bool_fast = fixed_point (
    fun gl ->
        create (fun ~size ~random ->
            let n = size in
            if n <= 0 then []
            else 
              let xs = generate (with_size gl (n-1)) ~size ~random in
              let x = generate bool ~size ~random in
              x::xs
        )
)

let gen_list_bool_faster = 
  let rec go ~size ~random =
      let n = size in
      if n <= 0 then []
      else 
        let x = Splittable_random.bool random in
        let xs = go ~size:(size - 1) ~random in
        x::xs
  in
  go

 *)

(* 
let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
  [
  Bench.Test.create_indexed ~name:"gen-list-basic" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.State.create (Random.State.make_self_init ()) in
    fun () -> generate gen_list_bool ~random ~size:n
  );
  Bench.Test.create_indexed ~name:"gen-list-fast" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.State.create (Random.State.make_self_init ()) in
    fun () -> generate gen_list_bool_fast ~random ~size:n
  );
  Bench.Test.create_indexed ~name:"gen-list-faster" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@
    let random = Splittable_random.State.create (Random.State.make_self_init ()) in
    fun () -> 
      gen_list_bool_faster ~size:n ~random
  )
] *)