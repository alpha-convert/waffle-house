open Core;;
open Fast_gen;;

open Core_bench;;

(*
let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
  [
  Bench.Test.create_indexed ~name:"gentree" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Basicgen.gen
  );
  Bench.Test.create_indexed ~name:"gen-manual-unfold" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Fastgen.gen_total
  );
  Bench.Test.create_indexed ~name:"gen-staged-splat" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Staged_treegen.splat
  );
]
  *)

module Fast_BST = struct
  type t = Bst.t
  let quickcheck_generator = Bst.g_fast
  let quickcheck_shrinker = Base_quickcheck.Shrinker.atomic
end

module Basic_BST = struct
  type t = Bst.t
  let quickcheck_generator = Bst.g_basic
  let quickcheck_shrinker = Base_quickcheck.Shrinker.atomic
end

type run_result = NoFailure of { total_time : float }
                | FoundFailure of { total_time : float }

exception TestFail

let ttf ~gen ~prop =
  let test t0 =
    Core.Quickcheck.test gen ~f:prop ~seed:`Nondeterministic ~trials:5000;
    let t1 = Core.Time_ns.now() in
    let diff = Core.Time_ns.Span.to_ns @@ Core.Time_ns.diff t1 t0 in
    NoFailure {total_time = diff}
  in
  let open Quickcheck.Generator in
  let t0 = Core.Time_ns.now () in
  try test t0 with
    _ -> let t1 = Core.Time_ns.now() in
           let diff = Core.Time_ns.Span.to_ns @@ Core.Time_ns.diff t1 t0 in
           FoundFailure {total_time = diff} 

let avg x xs =
  let (sum,num) = List.fold_left xs ~init:(x,1) ~f:(
    fun (s,n) x -> (s +. x, n + 1)
  ) in
  sum /. (Int.to_float num)

let stats ~gen ~samples ~prop =
  let rec go k =
    if equal k 0 then ([],[])
    else let (fails,no_fails) = go (k-1) in
         match ttf ~gen ~prop with
         | FoundFailure ff -> (ff.total_time::fails,no_fails)
         | NoFailure nf -> (fails,nf.total_time::no_fails)
  in
  match go samples with
  | ([],[]) -> (None,None)
  | (x::xs,[]) -> (Some (avg x xs),None)
  | ([],x::xs) -> (None, Some (avg x xs))
  | (x::xs,y::ys) -> (Some (avg x xs),Some (avg y ys))

let print_stats (mf,mnf) =
  (match mf with
  | None -> print_endline "No Fails"
  | Some f -> print_endline @@ "Average Fail Time: " ^ Float.to_string f
  );
  (match mnf with
  | None -> print_endline "No Non-Fails"
  | Some f -> print_endline @@ "Average Non-Fail Time: " ^ Float.to_string f
  )


let prop_insert_inv (k,v,t) = Bst.invariant (Bst.insert k v t)

let intopteq x y =
  match x,y with
  | None,None -> true
  | Some a,Some b -> equal a b
  | _,_ -> false

let prop_insert_find (k,v,t) = 
  if intopteq (Bst.find k (Bst.insert k v t)) (Some v) then ()
  else raise TestFail

let prop_insert_post (k,k',v,t) = 
  let comp = Bst.find k' (Bst.insert k v t) in
  let spec = if k == k' then Some v else Bst.find k' t in
  if intopteq comp spec then () else raise TestFail

  (* --> find k' (insert k v t)
  == if k == k' then Just v else find k' t *)


let () = print_stats @@ stats ~gen:Bst.g_insert_post_input ~prop:prop_insert_post ~samples:1000
let () = print_stats @@ stats ~gen:Bst.g_insert_post_input_fast ~prop: prop_insert_post ~samples:1000
(* let () = print_endline @@ Float.to_string @@ avg ~gen:Bst.g_insert_input_fast ~prop:prop_insert_find ~samples:100 *)


(* let insert_valid = Core.Quickcheck.test ~seed:`Nondeterministic ~trials:100000  ~f:(fun (k,v,t) -> Bst.invariant (Bst.insert k v t)) @@ *)
  (* _ *)
(* 
let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
  [
  Bench.Test.create_indexed ~name:"gen-bst" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Bst.g_basic
  );
  Bench.Test.create_indexed ~name:"gen-manual-unfold" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Bst.g_fast
  );
  Bench.Test.create_indexed ~name:"gen-staged-splat" ~args:[10;50;100;1000;10000] (
    fun n -> Staged.stage @@ fun () -> Quickcheck.random_value ~seed:`Nondeterministic ~size:n Staged_treegen.splat
  );
]
 *)

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