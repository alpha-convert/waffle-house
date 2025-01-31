open Core;;
open Core_bench;;

module BQ = struct
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
          ))

  let rec gen_list_bool_faster  ~size ~random  = 
    let n = size in
    if n <= 0 then []
    else 
      let x = Splittable_random.bool random in
      let xs = gen_list_bool_faster ~size:(size - 1) ~random in
      x::xs

  let rec gen_list_bool_faster_dropin  ~size ~random  = 
    let n = size in
    if n <= 0 then []
    else 
      let x = Unboxed_splitmix.DropIn.bool random in
      let xs = gen_list_bool_faster_dropin ~size:(size - 1) ~random in
      x::xs

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
end

module JoeSplitmix = struct
  let rec gen_list_bool_faster ~(size @ local) ~(random)  = 
    if size <= 0 then []
    else 
      let x = Unboxed_splitmix.bool random in
      x::(gen_list_bool_faster ~size:(size - 1) ~random)

  let rec gen_list_bool_imp ~size ~random  = 
    let n = ref size in
    let acc = ref [] in
    while !n > 0 do
      acc := (Unboxed_splitmix.bool random)::!acc;
      decr n
    done;
    !acc

  end

module QC = struct
  let gen_list_bool n =
    let open QCheck2.Gen in
    sized_size (return n) (fix (
        fun gl n ->
          if n <= 0 then return []
          else
            gl (n-1) >>= (fun xs ->
            bool >>= (fun x ->
              return (x::xs)
            ))

      )
    )

end

module CB = struct
  open Crowbar

  let gen_list_bool n = 
    let rec go n =
      if n <= 0 then const [] else
      map [bool;go (n-1)] (fun x xs -> x::xs)
    in go n
end

module RBTStaged = struct
  type color = R | B [@@deriving sexp, quickcheck]

  type tree = E | T of color *  tree * int * int * tree
  let rec gt ~size ~random =
    if size = 0 then
     (if (Float.(>=)) (Splittable_random.float random ~lo:0. ~hi:0.1) 0. then E else E)
    else
      let adjusted_size = Base.Int.pred size in
      if Float.(Splittable_random.float random ~lo:0. ~hi:0.2 >= 0.1) then
        T (
          (if Float.(Splittable_random.float random ~lo:0. ~hi:0.2 >= 0.1) then B else R),
          (
             gt
             ~size:adjusted_size
             ~random),
          ((Splittable_random.int random
              ~lo:Int.min_value ~hi:Int.max_value) mod 128),
          ((Splittable_random.int random
              ~lo:Int.min_value ~hi:Int.max_value) mod 128),
          (gt
             ~size:adjusted_size
             ~random)
        )
      else
        E
end

module RBTStagedFastIntDropIn = struct
  type color = R | B [@@deriving sexp, quickcheck]

  type tree = E | T of color *  tree * int * int * tree
  let rec gt ~size ~random =
    if size = 0 then
     (if (Float.(>=)) (Unboxed_splitmix.DropIn.float random ~lo:0. ~hi:0.1) 0. then E else E)
    else
      let adjusted_size = Base.Int.pred size in
      if Float.(Unboxed_splitmix.DropIn.float random ~lo:0. ~hi:0.2 >= 0.1) then
        T (
          (if Float.(Unboxed_splitmix.DropIn.float random ~lo:0. ~hi:0.2 >= 0.1) then B else R),
          (
             gt
             ~size:adjusted_size
             ~random),
          ((Unboxed_splitmix.DropIn.int random
              ~lo:Int.min_value ~hi:Int.max_value) mod 128),
          ((Unboxed_splitmix.DropIn.int random
              ~lo:Int.min_value ~hi:Int.max_value) mod 128),
          (gt
             ~size:adjusted_size
             ~random)
        )
      else
        E
end

module RBTStagedFastInt = struct
  type color = R | B [@@deriving sexp, quickcheck]

  type tree = E | T of color *  tree * int * int * tree
  let rec gt ~size ~random =
    if size = 0 then
     (if (Float.(>=)) (Unboxed_splitmix.float random ~lo:0. ~hi:0.1) 0. then E else E)
    else
      let adjusted_size = Base.Int.pred size in
      if Float.(Unboxed_splitmix.float random ~lo:0. ~hi:0.2 >= 0.1) then
        T (
          (if Float.(Unboxed_splitmix.float random ~lo:0. ~hi:0.2 >= 0.1) then B else R),
          (
             gt
             ~size:adjusted_size
             ~random),
          ((Unboxed_splitmix.int random
              ~lo:Int.min_value ~hi:Int.max_value) mod 128),
          ((Unboxed_splitmix.int random
              ~lo:Int.min_value ~hi:Int.max_value) mod 128),
          (gt
             ~size:adjusted_size
             ~random)
        )
      else
        E
end

let sizes = [10;50;100;1000;10000]

let () = List.iter sizes ~f:(fun n ->
    let random = Splittable_random.of_int 0 in
    let t = Quickcheck.Generator.generate BQ.gen_list_bool ~random ~size:n in
    print_endline @@ "Size: " ^ Int.to_string n ^ ", Words: " ^ Int.to_string (Obj.reachable_words (Obj.repr t))
  )

(* let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 5) ())
  [
  (* Bench.Test.create_indexed ~name:"bq-gen-list-basic" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> Quickcheck.Generator.generate BQ.gen_list_bool ~random ~size:n
  ); *)
  (* Bench.Test.create_indexed ~name:"bq-gen-list-fast" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> Quickcheck.Generator.generate BQ.gen_list_bool_fast ~random ~size:n
  ); *)
  Bench.Test.create_indexed ~name:"bq-gen-list-faster" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> BQ.gen_list_bool_faster ~size:n ~random
  );
  (* Bench.Test.create_indexed ~name:"bq-gen-list-faster-det" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> BQ.gen_list_bool_faster_det ~size:n ~random
  ); *)
  (* Bench.Test.create_indexed ~name:"bq-gen-list-trmc" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> BQ.gen_list_bool_trmc ~size:n ~random
  ); *)
  (* Bench.Test.create_indexed ~name:"bq-gen-list-imp" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> BQ.gen_list_bool_imp ~size:n ~random
  );
  Bench.Test.create_indexed ~name:"qc-gen-list-basic" ~args:sizes (
    fun n -> Staged.stage @@ 
    let g = QC.gen_list_bool n in
    fun () -> (QCheck2.Gen.generate1 g)
  ); *)
  Bench.Test.create_indexed ~name:"sm-gen-list-faster" ~args:sizes (
    fun n -> Staged.stage @@ 
    let u = Random.State.make_self_init () in
    let s = Unboxed_splitmix.of_int (Random.State.int u Int.max_value) in
    fun () -> (JoeSplitmix.gen_list_bool_faster ~size:n ~random:s)
  );


  Bench.Test.create_indexed ~name:"bq-gen-list-faster-dropin" ~args:sizes (
    fun n -> Staged.stage @@
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> BQ.gen_list_bool_faster_dropin ~size:n ~random
  );


  (* Bench.Test.create_indexed ~name:"sm-gen-list-imp" ~args:sizes (
    fun n -> Staged.stage @@ 
    let u = Random.State.make_self_init () in
    let s = Unboxed_splitmix.of_int (Random.State.int u Int.max_value) in
    fun () -> (JoeSplitmix.gen_list_bool_imp ~size:n ~random:s)
  ); *)
]

*)

let () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 30) ())
  [
  Bench.Test.create_indexed ~name:"rbt-staged" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> (RBTStaged.gt ~size:n ~random:random)
  );
  Bench.Test.create_indexed ~name:"rbt-staged-fast-int-dropipn" ~args:sizes (
    fun n -> Staged.stage @@ 
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () -> (RBTStagedFastIntDropIn.gt ~size:n ~random:random)
  );

  Bench.Test.create_indexed ~name:"rbt-staged-fast-int" ~args:sizes (
    fun n -> Staged.stage @@ 
    let u = Random.State.make_self_init () in
    let random = Unboxed_splitmix.of_int (Random.State.int u Int.max_value) in
    fun () -> (RBTStagedFastInt.gt ~size:n ~random:random)
  );
  ]