open Core
open Fast_gen
open BaseType
open BaseBespoke
open BaseTypeStaged
open Core_bench;;

(* Helper functions to calculate tree size and depth *)
let rec tree_size = function
  | Impl.E -> 0
  | Impl.T (_, left, _, _, right) -> 1 + tree_size left + tree_size right

let rec tree_depth = function
  | Impl.E -> 0
  | Impl.T (_, left, _, _, right) -> 1 + Int.max (tree_depth left) (tree_depth right)

(* Benchmark with size and depth measurements *)
let measure_tree_properties ~generator ~size ~trials =
  let results =
    List.init trials ~f:(fun _ ->
        let tree = Quickcheck.random_value ~seed:`Nondeterministic ~size generator in
        (tree_size tree, tree_depth tree))
  in
  let total_size, total_depth =
    List.fold results ~init:(0, 0) ~f:(fun (sum_size, sum_depth) (size, depth) ->
        (sum_size + size, sum_depth + depth))
  in
  let avg_size = Float.of_int total_size /. Float.of_int trials in
  let avg_depth = Float.of_int total_depth /. Float.of_int trials in
  (avg_size, avg_depth)

let () =
  let sizes = [10; 50; 100; 1000; 10000] in
  let trials = 100 in (* Number of trials per size *)

  List.iter sizes ~f:(fun size ->
      let avg_size_type, avg_depth_type =
        measure_tree_properties ~generator:BaseType.quickcheck_generator ~size ~trials
      in
      let avg_size_bespoke, avg_depth_bespoke =
        measure_tree_properties ~generator:BaseBespoke.quickcheck_generator ~size ~trials
      in
      let avg_size_staged, avg_depth_staged =
        measure_tree_properties ~generator:BaseTypeStaged.quickcheck_generator ~size ~trials
      in
      printf "Size: %d\n" size;
      printf "  BaseType: avg_size = %.2f, avg_depth = %.2f\n" avg_size_type avg_depth_type;
      printf "  BaseBespoke: avg_size = %.2f, avg_depth = %.2f\n" avg_size_bespoke avg_depth_bespoke;
      printf "  BaseTypeStaged: avg_size = %.2f, avg_depth = %.2f\n\n" avg_size_staged avg_depth_staged);

  Bench.bench
    ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
    [
      Bench.Test.create_indexed ~name:"gen_type" ~args:sizes (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n BaseType.quickcheck_generator
      );
      Bench.Test.create_indexed ~name:"gen_bespoke" ~args:sizes (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n BaseBespoke.quickcheck_generator
      );
      Bench.Test.create_indexed ~name:"gen_type_staged" ~args:sizes (
        fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n BaseTypeStaged.quickcheck_generator
      );
    ]
