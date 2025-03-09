open! Core

module Private = struct
  let stop_symbol = "magic_trace_stop_indicator"
end

external stop_indicator : int -> int -> unit = "magic_trace_stop_indicator" [@@noalloc]

let start_time = ref 0

let[@inline] tsc_int () =
  let tsc = Time_stamp_counter.now () in
  Time_stamp_counter.to_int63 tsc |> Int63.to_int_exn
;;

let mark_start () = start_time := tsc_int ()

module Min_duration = struct
  type t = int

  let of_ns ns =
    Time_stamp_counter.Span.of_ns
      (Int63.of_int ns)
      ~calibrator:(force Time_stamp_counter.calibrator)
    |> Time_stamp_counter.Span.to_int_exn
  ;;

  let over min =
    let span = tsc_int () - !start_time in
    span > min
  ;;
end

let take_snapshot_with_arg i = stop_indicator !start_time i

let take_snapshot_with_time_and_arg tsc i =
  let tsc_i = Time_stamp_counter.to_int63 tsc |> Int63.to_int_exn in
  stop_indicator tsc_i i
;;

let take_snapshot () = take_snapshot_with_arg 0

open Core_bench

let wait_for_enter () =
  Printf.printf "Press Enter to continue when MT attached...";
  Out_channel.flush stdout;
  let _ = In_channel.input_line In_channel.stdin in
  ()

let under_bm ~name ~gen ~size ~num_calls ~seed ~min_dur_to_trigger =
  wait_for_enter ();
  Bench.bench
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls num_calls) ())
  @@
  [
    let random = Splittable_random.State.of_int seed in
    Bench.Test.create ~name @@ fun () ->
      mark_start();
      ignore (Base_quickcheck.Generator.generate gen ~size:size ~random:random);
      if Min_duration.over min_dur_to_trigger then take_snapshot ()

    ]
    (* Bench.Test.create_parameterised ~name:(bench_name ^ "_" ^ gen_name) ~args:(List.map ~f:(fun (sz,sd) -> ("n=" ^ Int.to_string sz ^ ",r=" ^ Int.to_string sd,(sz,sd))) @@ cartesian sizes seeds) @@ *)
      (* fun (size,seed) -> *)
        (* Staged.stage @@ fun () -> *)
          (* ignore (Base_quickcheck.Generator.generate g ~size:size ~random:random); *)