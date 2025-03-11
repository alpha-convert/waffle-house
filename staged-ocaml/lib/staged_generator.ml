(* open Core;; *)
open Codelib;;
open Codecps;;
(* open Codecps.Let_syntax;; *)

module MakeStaged(R : Random_intf.S) = struct

  type 'a t = { rand_gen : size_c:(int code) -> random_c:(R.t code) -> 'a Codecps.t }

(*
  Codegen stuff...
  *)

  let split_bool cb = {
    rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.split_bool cb
  }

  let split_int cn = {
    rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.split_int cn
  }

  let split_pair cp = {
    rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.split_pair cp
  }

  let split_triple ct = {
    rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.split_triple ct
  }

  let split_list cxs = {
    rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.split_list cxs
  }

  let split_option cxs = {
    rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.split_option cxs
  }

  module MakeSplit(X : Splittable.S) = struct
    let split cx = {
      rand_gen = fun ~size_c:_ ~random_c:_ -> X.split cx
    }
  end

  module R = R

  module C = struct
    type 'a t = 'a code
    let lift x = .< x >.
    let pair x y = .< (.~x,.~y) >.
    let i2f x = .< Float.of_int .~x >.
    let pred n = .< .~n - 1 >.
    let cons x xs = .< .~x :: .~xs >.
    let modulus x n = .< .~x mod n >.
  end

  type 'a c = 'a C.t
  (* type 'a recgen = (unit -> 'a Core.Quickcheck.Generator.t) code *)

  let return x = { rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.return x }

  (*
  Ideally, we would really rather have this bind perform a let-insertion to ensure that effect order
  is *always* preserved. I.e. bind would look like:
  ```
  Codecps.bind (r.rand_gen ~size_c ~random_c) @@ fun a ->
    Codecps.bind (Codecps.let_insert a) @@ fun a ->
        (f a).rand_gen ~size_c ~random_c
  ```
  In this way, we would ensure that in the generated code we *always* run the effectful computation `r` before
  passing the result to the continuation, rather than just substituting the code for `r` into the place that `f` uses its argumetn.
  But for type reasons, this doesn't work. In order to do "the trick",
  we must have that `type 'a t = { rand_gen : size_c:(int code) -> random_c:(R.t code) -> 'a Codecps.t }`
  and not `type 'a t = { rand_gen : size_c:(int code) -> random_c:(R.t code) -> 'a code Codecps.t }` (note the `code` in the result type).
  This prevents us from adding a let-insert.

  So, in order to ensure that effects happen in the right order, we are very careful to ensure that any library combinator that
  might perform effects (or recursion) has a Codecps.let_insert at the top level, so that it hits the bind in the same way.
  *)
  let bind (r : 'a t) ~(f : 'a -> 'b t) = { rand_gen = fun ~size_c ~random_c ->
    Codecps.bind (r.rand_gen ~size_c ~random_c) (fun a ->
        (f a).rand_gen ~size_c ~random_c
    )
  }

  let map x ~f = bind x ~f:(fun cx -> return (f cx))

  let apply f x = bind f ~f:(fun f -> bind x ~f:(fun x -> return (f x)))

  module For_applicative = Base.Applicative.Make (struct
      type nonrec 'a t = 'a t

      let return = return
      let apply = apply
      let map = `Custom map
    end)

  let both = For_applicative.both
  let map2 = For_applicative.map2
  let map3 = For_applicative.map3

  module Applicative_infix = For_applicative.Applicative_infix
  include Applicative_infix

  module For_monad = Base.Monad.Make (struct
      type nonrec 'a t = 'a t

      let return = return
      let bind x ~f = bind x ~f
      let map = `Define_using_bind
    end)

  include For_monad
  include Monad_infix


  let bool : bool code t = {
    rand_gen =
      fun ~size_c:_ ~random_c ->
        (* adding these let-inserts here ensures that the effects happen in order of the binds. *)
        Codecps.let_insert (R.bool random_c)
  }

  

  let float_uniform_exclusive ~(lo : float code) ~(hi : float code) : float code t = {
    rand_gen =
      fun ~size_c:_ ~random_c ->
        Codecps.bind (Codecps.let_insert (R.one_ulp ~dir:`Up lo)) @@ fun lo_incl ->
        Codecps.bind (Codecps.let_insert (R.one_ulp ~dir:`Down hi)) @@ fun hi_incl ->
        Codecps.let_insert (R.float random_c ~lo:lo_incl ~hi:hi_incl)
  }

  let float_uniform_inclusive ~(lo : float code) ~(hi : float code) : float code t = {
    rand_gen =
      fun ~size_c:_ ~random_c ->
        Codecps.let_insert (R.float random_c ~lo:lo ~hi:hi)
  }

  let rec genpick n ws =
    match ws with
    | [] -> { rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.error "Fell of the end of pick list" }
    | (k,g) :: ws' ->
          { rand_gen = 
            fun ~size_c ~random_c ->
              Codecps.bind (Codecps.split_bool .< Float.compare .~(v2c n) .~(v2c k) <= 0 >.) (fun leq ->
                if leq then
                  g.rand_gen ~size_c ~random_c
                else
                  Codecps.bind (Codecps.let_insertv .< .~(v2c n) -. .~(v2c k) >.) @@ fun n' ->
                  (* let%bind n' =  in *)
                  (genpick n' ws').rand_gen ~size_c ~random_c
            )
          }

    
  let sum (ws : (float val_code * 'a t) list) : (float code) Codecps.t =
      let rec go (ws : (float val_code * 'a t) list) (acc : float code) : (float code) Codecps.t =
        match ws with
        | [] -> Codecps.return acc
        | (cn,_) :: ws' ->
            go ws' .< .~acc +. .~(v2c cn) >.
        in
      go ws .<0.>.

  let weighted_union ws : 'a t =
    { rand_gen = fun ~size_c ~random_c ->
        Codecps.bind (Codecps.all @@ List.map (fun (cn,g) -> Codecps.bind (Codecps.let_insertv cn) @@ fun cvn -> Codecps.return (cvn,g)) ws) @@ fun ws' ->
        Codecps.bind (sum ws') @@ fun sum ->
        Codecps.bind (Codecps.let_insertv sum) @@ fun sum' ->
        let n = (R.float random_c ~lo:.<0.>. ~hi:(v2c sum')) in
        Codecps.bind (Codecps.let_insertv n) @@ fun n ->
        (genpick n ws').rand_gen ~size_c ~random_c
    }

let int_uniform_inclusive ~(lo : int code) ~(hi : int code) : int code t = {
    rand_gen =
      fun ~size_c:_ ~random_c ->
        Codecps.let_insert (R.int random_c ~lo:lo ~hi:hi)
  }

  let int_log_uniform_inclusive ~(lo : int code) ~(hi : int code) : int code t = {
    rand_gen =
      fun ~size_c:_ ~random_c ->
        Codecps.let_insert (R.Log_uniform.int random_c ~lo:lo ~hi:hi)
  }


  (*
  NON-uniform is literally just this:
  >> weighted_union [ .< 0.05 >., return lo; .<0.05>., return hi; .<0.9>., f ~lo ~hi ]
  but we specialize further to cut down on code size.
  *)
  let non_uniform f ~lo ~hi =
    { rand_gen = fun ~size_c ~random_c ->
        let n = (R.float_unchecked random_c ~lo:.<0.>. ~hi:.<1.0>.) in
        Codecps.bind (Codecps.let_insertv n) @@ fun n ->
        Codecps.bind (Codecps.split_bool .< Float.compare .~(v2c n) 0.05 <= 0 >.) @@ fun leq_first ->
          if leq_first then
            Codecps.return lo
          else
            Codecps.bind (Codecps.split_bool .< Float.compare .~(v2c n) 0.1 <= 0 >.) @@ fun leq_second ->
              if leq_second then
                Codecps.return hi
              else
                (f ~lo ~hi).rand_gen ~size_c ~random_c
    }

  let int_inclusive = non_uniform int_uniform_inclusive
  let int_log_inclusive = non_uniform int_log_uniform_inclusive
  let uniform_all = int_uniform_inclusive ~lo:.<Int.min_int>. ~hi:.<Int.max_int>.

  let int_uniform = uniform_all

  let int =
    bind bool ~f:(fun negative ->
        bind (int_log_inclusive ~lo:.<0>. ~hi:.<Base.Int.max_value>.) ~f:(fun magnitude ->
          return .<.~magnitude lxor (- Base.Bool.to_int .~negative)>.
          )
    )
    (* let all =
      [%map
        let negative = bool
        and magnitude = log_inclusive Integer.zero Integer.max_value in
        if negative then Integer.bit_not magnitude else magnitude] *)

  let of_list (xs : 'a list) : 'a t =
    let n = List.length xs - 1 in
    let rec go (i : int code) (xs : 'a list) : 'a t =
      match xs with
      | [] -> failwith "empty list!"
      | [x] -> return x
      | x::xs -> { rand_gen = fun ~size_c ~random_c ->
          Codecps.bind (Codecps.split_bool .< .~i == 0 >.) @@ fun b ->
          if b then Codecps.return x else
            Codecps.bind (Codecps.let_insert .< .~i - 1 >.) @@ fun i_pred ->
              (go i_pred xs).rand_gen ~size_c ~random_c
        }
    in
    bind (int_uniform_inclusive ~lo:.<0>. ~hi:.<n>.) ~f:(fun i ->
      go i xs
    )

  let union xs = join (of_list xs)



  let of_list_dyn cxs =
    let of_list_dyn_loop = Codelib.genlet .<
        let rec go xs i =
          match xs with
          | [] -> failwith "Impossible"
          | y::ys -> if i == 0 then y else go ys (i-1)
        in go
        >.
      in
    {
    rand_gen = fun ~size_c ~random_c ->
      Codecps.bind (Codecps.let_insert cxs) @@ fun cxs ->
      Codecps.bind (Codecps.let_insert .<List.length .~cxs - 1>.) @@ fun n ->
      Codecps.bind ((int_uniform_inclusive ~lo:.<0>. ~hi:.<.~n>.).rand_gen ~size_c ~random_c) @@ fun i ->
      Codecps.return .<
        if .~n < 0 then failwith "of_list_dn passed empty list" else .~of_list_dyn_loop .~cxs .~i
      >.
  }


  let with_size f ~size_c =
    { rand_gen = fun ~size_c:_ ~random_c -> f.rand_gen ~size_c:size_c ~random_c }

  let size = { rand_gen = fun ~size_c ~random_c:_ -> Codecps.return size_c }

  let list g =
    (* NOTE: this is a place where we could go way faster, if we wanted to move the effects around but keep the distribution the same  *)
    let go len = {
      rand_gen = fun ~size_c ~random_c ->
        Codecps.bind (Codecps.let_insert .<Array.make .~len 0>.) @@ fun sizes ->
        Codecps.bind (Codecps.let_insert .<.~size_c - .~len>.) @@ fun remaining ->
        Codecps.bind (Codecps.let_insert .<.~len - 1>.) @@ fun max_index ->
        Codecps.bind (Codecps.seq_insert .<
          for _ = 1 to .~remaining do
            let i = .~(R.Log_uniform.int random_c ~lo:.<0>. ~hi:max_index) in
            .~sizes.(i) <- .~sizes.(i) + 1
          done
        >.) @@ fun () ->
        Codecps.bind (Codecps.seq_insert .<
          for i = 0 to .~max_index - 1 do
            let j = .~(R.int random_c ~lo:.<i>. ~hi:max_index) in
            let tmp = .~sizes.(i) in
            .~sizes.(i) <- .~sizes.(j);
            .~sizes.(j) <- tmp
          done
        >.) @@ fun () ->
        Codecps.bind (Codecps.let_insert_smart .<
          fun sz ->
            .~(Codecps.code_generate (g.rand_gen ~size_c:.<sz>. ~random_c))
        >.) @@ fun f ->
          Codecps.return .<
            List.map .~f (Array.to_list .~sizes)
          >.
    }
    in

    bind size ~f:(fun sz ->
      bind (int_log_uniform_inclusive ~lo:.<0>. ~hi:sz) ~f:(fun len -> 
        bind (split_int len) ~f:(fun slen ->
          match slen with
          | `Z -> return .<[]>.
          | `S _ -> go len
        )
      )
    )

  let if_z cx gz gsucc =
    bind (split_int cx) ~f:(function
    | `Z -> gz
    | `S _ -> gsucc
    )

  let to_bq sg =
    .<
      Base_quickcheck.Generator.create (fun ~size ~random ->
        .~(
            let local_random = genlet (R.of_sr .<random>.) in
            Codecps.code_generate (sg.rand_gen ~size_c:.<size>. ~random_c:local_random)
          )
      )
    >.


  let print sg = Codelib.print_code Format.std_formatter (to_bq sg)

  let jit ?extra_cmi_paths cde =
    List.iter Runnative.add_search_path (List.flatten (Option.to_list extra_cmi_paths));
    List.iter Runnative.add_search_path R.dep_paths;
    Runnative.add_search_path (Util.run_ocamlfind_query "base_quickcheck");
    Runnative.add_search_path ((Util.run_ocamlfind_query "base") ^ " -O3 -w -26");
    (* this is one of the evilest hacks i've ever pulled. runnative doesn't let
    you pass flags to ocamlopt explicitly, so i just inject them onto the end of
    one of the dependencies. It constructs the ocamlopt call directly from this string. *)
    Runnative.run_native (Codelib.close_code (to_bq cde))


  type ('a,'r) recgen = 'r code -> 'a code t
  let recurse f x = {
    rand_gen = fun ~size_c ~random_c ->
      Codecps.bind ((f x).rand_gen ~size_c ~random_c) @@ fun c ->
      Codecps.let_insert c
  }

  let recursive (type a) (type r) (x0 : r code) (step : (a,r) recgen -> r code -> a code t) =
    {
      rand_gen = fun ~size_c ~random_c -> 
        Codecps.bind (Codecps.let_insertv x0) @@ fun x0 ->
        (* let%bind x0 = Codecps.let_insert x0 in *)
        Codecps.let_insert @@ .< let rec go x ~size ~random = .~(
            Codecps.code_generate @@
              (step
                  (fun xc' -> { rand_gen = fun ~size_c ~random_c -> Codecps.return .< go .~xc' ~size:.~size_c ~random:.~random_c >. })
                  .<x>.
              ).rand_gen ~size_c:.<size>. ~random_c:.<random>.
          )
          in
            go .~(v2c x0) ~size:.~size_c ~random:.~random_c
        >.
    }
end