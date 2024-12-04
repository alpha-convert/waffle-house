open Core;;
open Core_bench;;

let gen_list_bool =
  let open Base_quickcheck.Generator in
  let open Base_quickcheck.Generator.Let_syntax in
  fixed_point (
    fun gl ->
        let%bind n = size in
        if n <= 0 then return [] else
          let%bind xs = with_size ~size:(n-1) gl in
          let%bind x = bool in
          return (x :: xs)
)

let gen_list_bool_fast =
  let open Base_quickcheck.Generator in
  fixed_point (
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

let rec gen_list_bool_faster  ~size ~random  = 
  let n = size in
  if n <= 0 then []
  else 
    let x = Splittable_random.bool random in
    let xs = gen_list_bool_faster ~size:(size - 1) ~random in
    x::xs

let rec gen_list_bool_faster_det  ~size ~random  = 
  let n = size in
  if n <= 0 then []
  else false::(gen_list_bool_faster ~size:(size - 1) ~random)



let[@tail_mod_cons] rec gen_list_bool_trmc ~(size @ local) ~random  = 
  let n = size in
  if n <= 0 then []
  else 
    let x = Splittable_random.bool random in
    x::(gen_list_bool_trmc ~size:(size - 1) ~random)
    
let rec gen_list_bool_imp ~size ~random  = 
  let n = ref size in
  let acc = ref [] in
  while !n > 0 do
    acc := (Splittable_random.bool random)::!acc;
    decr n
  done;
  !acc

let sizes = [10;50;100;1000;10000]

let () = List.iter sizes ~f:(fun n ->
    let random = Splittable_random.of_int 0 in
    let t = Quickcheck.Generator.generate gen_list_bool ~random ~size:n in
    print_endline @@ "Size: " ^ Int.to_string n ^ ", Words: " ^ Int.to_string (Obj.reachable_words (Obj.repr t))
  )

let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5000) ())
  [
  Bench.Test.create_indexed ~name:"gen-list-basic" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> Quickcheck.Generator.generate gen_list_bool ~random ~size:n
  );
  Bench.Test.create_indexed ~name:"gen-list-fast" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> Quickcheck.Generator.generate gen_list_bool_fast ~random ~size:n
  );
  Bench.Test.create_indexed ~name:"gen-list-faster" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> 
      gen_list_bool_faster ~size:n ~random
  );
  Bench.Test.create_indexed ~name:"gen-list-faster-det" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> 
      gen_list_bool_faster_det ~size:n ~random
  );
  Bench.Test.create_indexed ~name:"gen-list-trmc" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> 
      gen_list_bool_trmc ~size:n ~random
  );
  Bench.Test.create_indexed ~name:"gen-list-imp" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> 
      gen_list_bool_imp ~size:n ~random
  )
]