(* type state *)

(* external of_int : Int64.t -> state = "of_int" *)

module UI64 = Stdlib_upstream_compatible.Int64_u

(* external bool : state -> bool = "bool" *)

type t = { mutable seed : int64#; odd_gamma : int64# }

let of_int seed = { seed = UI64.of_int64 seed; odd_gamma = #0x9e37_79b9_7f4a_7c15L}

let copy { seed; odd_gamma } = { seed; odd_gamma }

let mix_bits z n = UI64.logxor z (UI64.shift_right_logical z n)

let mix64 z =
  let z = UI64.mul (mix_bits z 33) #0xff51_afd7_ed55_8ccdL in
  let z = UI64.mul (mix_bits z 33) #0xc4ce_b9fe_1a85_ec53L in
  mix_bits z 33
;;

let mix64_variant13 z =
  let z = UI64.mul (mix_bits z 30) #0xbf58_476d_1ce4_e5b9L in
  let z = UI64.mul (mix_bits z 27) #0x94d0_49bb_1331_11ebL in
  mix_bits z 31
;;

(* let mix_odd_gamma z =
  let z = UI64.logor (mix64_variant13 z) #1L in
  let n = 
    popcount (z lxor (z lsr 1)) in
  (* The original paper uses [>=] in the conditional immediately below; however this is
     a typo, and we correct it by using [<]. This was fixed in response to [1] and [2].

     [1] https://github.com/janestreet/splittable_random/issues/1
     [2] http://www.pcg-random.org/posts/bugs-in-splitmix.html
  *)
  if Int.( < ) n 24 then z lxor 0xaaaa_aaaa_aaaa_aaaaL else z
;; *)

let next_seed t =
  let next = UI64.add t.seed t.odd_gamma in
  t.seed <- next;
  next
;;
(* 
let of_seed_and_gamma ~seed ~gamma =
  let seed = mix64 seed in
  let odd_gamma = mix_odd_gamma gamma in
  { seed; odd_gamma }
;; *)

(* let random_int64 random_state = *)
  (* Random.State.int64_incl random_state Int64.min_value Int64.max_value *)
;;
(* 
let create random_state =
  let seed = random_int64 random_state in
  let gamma = random_int64 random_state in
  of_seed_and_gamma ~seed ~gamma
;;

let split t =
  let seed = next_seed t in
  let gamma = next_seed t in
  of_seed_and_gamma ~seed ~gamma
;; *)

let next_int64 t = mix64 (next_seed t)

(* [perturb] is not from any external source, but provides a way to mix in external
   entropy with a pseudo-random state. *)
let perturb t salt =
  let next = UI64.add t.seed (mix64 (UI64.of_int salt)) in
  t.seed <- next
;;

let bool state = 
  UI64.equal (UI64.logand (next_int64 state) #1L) #0L