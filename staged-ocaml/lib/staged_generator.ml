(* open Core;; *)
open Codelib;;
open Codecps;;
(* open Codecps.Let_syntax;; *)

type 'a t = { rand_gen : size_c:(int code) -> random_c:(Splittable_random.State.t code) -> 'a Codecps.t }




module C = struct
  type 'a t = 'a code
  let lift x = .< x >.
  let pair x y = .< (.~x,.~y) >.
  let i2f x = .< Float.of_int .~x >.
  let pred n = .< .~n - 1 >.
  let cons x xs = .< .~x :: .~xs >.
end

type 'a c = 'a C.t
(* type 'a recgen = (unit -> 'a Core.Quickcheck.Generator.t) code *)

let return x = { rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.return x }

let bind (r : 'a t) ~(f : 'a -> 'b t) = { rand_gen = fun ~size_c ~random_c ->
  Codecps.bind (r.rand_gen ~size_c ~random_c) (fun a ->
      (f a).rand_gen ~size_c ~random_c
  )
}

let join (x : 'a t t) : 'a t = bind x ~f:(fun z -> z)

let map ~f x = bind x ~f:(fun cx -> return (f cx))

let map2 ~f x y = bind x ~f:(fun x -> bind y ~f:(fun y -> return (f x y)))

let ( >>= ) x f = bind x ~f
let ( >>| ) (x : 'a t) (f : 'a -> 'b) = map ~f x

let bool : bool code t = {
  rand_gen =
    fun ~size_c:_ ~random_c ->
      (* adding these let-inserts here ensures that the effects happen in order of the binds. *)
      Codecps.let_insert .< Splittable_random.bool .~random_c >.
}

let int ~(lo : int code) ~(hi : int code) : int code t = {
  rand_gen =
    fun ~size_c:_ ~random_c ->
      Codecps.let_insert .< Splittable_random.int ~lo:.~lo ~hi:.~hi .~random_c >.
}

let float ~(lo : float code) ~(hi : float code) : float code t = {
  rand_gen =
    fun ~size_c:_ ~random_c ->
      Codecps.let_insert .< Splittable_random.float ~lo:.~lo ~hi:.~hi .~random_c >.
}

let rec genpick n ws =
  match ws with
  | [] -> { rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.return .< failwith "Fell of the end of pick list" >. }
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

  
let sum (ws : (float val_code * 'a t) list) : (float val_code) Codecps.t =
    let rec go (ws : (float val_code * 'a t) list) (acc : float val_code) : (float val_code) Codecps.t =
      match ws with
      | [] -> Codecps.return acc
      | (cn,_) :: ws' ->
          Codecps.bind (Codecps.let_insertv .< .~(v2c acc) +. .~(v2c cn) >.) @@ fun acc' ->
          (* let%bind acc' =  in *)
          go ws' acc'
      in
    Codecps.bind (let_insertv .< 0. >.) @@ fun zero ->
    go ws zero

let weighted_union ws : 'a t =
  { rand_gen = fun ~size_c ~random_c ->
      Codecps.bind (Codecps.all @@ List.map (fun (cn,g) -> Codecps.bind (Codecps.let_insertv cn) @@ fun cvn -> Codecps.return (cvn,g)) ws) @@ fun ws' ->
      (* let%bind ws' =  in *)
      Codecps.bind (sum ws') @@ fun sum ->
      (* let%bind sum = sum ws' in *)
      Codecps.bind ((float ~lo:.<0.>. ~hi:(v2c sum)).rand_gen ~size_c ~random_c) @@ fun n ->
      (* let%bind n =  in *)
      Codecps.bind (Codecps.let_insertv n) @@ fun n ->
      (* let%bind n = Codecps.let_insert n in *)
      (genpick n ws').rand_gen ~size_c ~random_c
  }


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
  bind (int ~lo:.<0>. ~hi:.<n>.) ~f:(fun i ->
    go i xs
  )

let union xs = join (of_list xs)

(* g is a 'a list gen *)
(* let dynamic_union g =
  bind g ~f:(fun cxs -> {
      rand_gen = fun ~size_c ~random_c ->
        Codecps.bind (Codecps.let_insert .< List.length .~cxs >.) @@ fun len ->
        Codecps.bind ((int ~lo:.<0>. ~hi:len).rand_gen ~size_c ~random_c) @@ fun n ->
        _
    }
  )
   *)

let with_size f ~size_c =
  { rand_gen = fun ~size_c:_ ~random_c -> f.rand_gen ~size_c:size_c ~random_c }

let size = { rand_gen = fun ~size_c ~random_c:_ -> Codecps.return size_c }

let to_fun sg = 
  let f = sg.rand_gen in
  .< fun ~size ~random ->
      .~(Codecps.code_generate (f ~size_c:.< size >. ~random_c:.< random >.))
  >.

(* let to_qc sg =
  .<
    Base_quickcheck.Generator.create .~(to_fun sg)
  >. *)


let print sg = Codelib.print_code Format.std_formatter (to_fun sg)

let run_ocamlfind_query package =
  let cmd = Printf.sprintf "ocamlfind query %s" package in
  let ic = Unix.open_process_in cmd in
  match In_channel.input_line ic with
  | Some path -> 
      ignore (Unix.close_process_in ic); 
      Runnative.add_search_path path
  | None -> 
      ignore (Unix.close_process_in ic); 
      failwith ("Could not find " ^ package)

let () =
  List.iter run_ocamlfind_query
    [ "splittable_random"; "base" ]

(* LMFAO I CANNOT BELIEVE THIS WORKS *)
let jit cde = Runnative.run_native (Codelib.close_code (to_fun cde))

type ('a,'r) recgen = 'r code -> 'a code t
let recurse f x = f x

let recursive (type a) (type r) (x0 : r code) (step : (a,r) recgen -> r code -> a code t) =
  {
    rand_gen = fun ~size_c ~random_c -> 
      Codecps.bind (Codecps.let_insertv x0) @@ fun x0 ->
      (* let%bind x0 = Codecps.let_insert x0 in *)
      Codecps.return @@ .< let rec go x ~size ~random = .~(
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

(*
Codegen stuff...
*)

let split_bool cb = {
  rand_gen = fun ~size_c:_ ~random_c:_ -> Codecps.split_bool cb
}