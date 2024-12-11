open Core
(* type state *)
type t = { mutable seed : int64#; odd_gamma : int64# }

module I = Stdlib_upstream_compatible.Int64_u

let of_int seed = { seed = I.of_int seed; odd_gamma = #0x9e37_79b9_7f4a_7c15L}

let copy { seed; odd_gamma } = { seed; odd_gamma }

(* we specialize three different versions of this to esnure that the `int` argument to I.shift_right_logical is
never boxed in the library. *)
let [@inline always] mix_bits_33 z = I.logxor z (I.shift_right_logical z 33)
let [@inline always] mix_bits_27 z = I.logxor z (I.shift_right_logical z 27)
let [@inline always] mix_bits_30 z = I.logxor z (I.shift_right_logical z 30)
let [@inline always] mix_bits_31 z = I.logxor z (I.shift_right_logical z 31)

let mix64 z =
  let z = I.mul (mix_bits_33 z) #0xff51_afd7_ed55_8ccdL in
  let z = I.mul (mix_bits_33 z) #0xc4ce_b9fe_1a85_ec53L in
  mix_bits_33 z
;;

let mix64_variant13 z =
  let z = I.mul (mix_bits_30 z) #0xbf58_476d_1ce4_e5b9L in
  let z = I.mul (mix_bits_27 z) #0x94d0_49bb_1331_11ebL in
  mix_bits_31 z
;;

let mix_odd_gamma z =
  let z = I.logor (mix64_variant13 z) #1L in
  (* TODO use immediate popcount here... ocaml intrinsics isn't building on arm64. *)
  let n = Core.Int64.popcount (I.to_int64 (I.logxor z (I.shift_right_logical z 1))) in
  if n < 24 then I.logxor z #0xaaaa_aaaa_aaaa_aaaaL else z

let next_seed t =
  let next = I.add t.seed t.odd_gamma in
  t.seed <- next;
  next
;;

let of_seed_and_gamma ~seed ~gamma =
  let seed = mix64 seed in
  let odd_gamma = mix_odd_gamma gamma in
  { seed; odd_gamma }

let random_int64u random_state =
  I.of_int64 (Core.Random.State.int64_incl random_state Core.Int64.min_value Core.Int64.max_value)

let create random_state =
  let seed = random_int64u random_state in
  let gamma = random_int64u random_state in
  of_seed_and_gamma ~seed ~gamma

let split t =
  let seed = next_seed t in
  let gamma = next_seed t in
  of_seed_and_gamma ~seed ~gamma

let next_int64 t = mix64 (next_seed t)

let perturb t salt =
  let next = I.add t.seed (mix64 (I.of_int salt)) in
  t.seed <- next
;;

let bool (state @ local) = 
  I.equal (I.logand (next_int64 state) #1L) #0L

(*let remainder_is_unbiased ~draw ~remainder ~draw_maximum ~remainder_maximum =
    I.compare (I.sub draw remainder) (I.sub draw_maximum remainder_maximum) <= 0
*)

(*
let int64 =
  let rec between state ~lo ~hi =
    let draw = next_int64 state in
    if lo <= draw && draw <= hi then draw else between state ~lo ~hi
  in
  let rec non_negative_up_to state maximum =
    let draw = I.logand (next_int64 state) (I.of_int64 Int64.max_value) in
    let remainder = I.rem draw (I.succ maximum) in
    if remainder_is_unbiased
          ~draw
          ~remainder
          ~draw_maximum:(I.of_int64 Int64.max_value)
          ~remainder_maximum:maximum
    then remainder
    else non_negative_up_to state maximum
  in
  fun state ~lo ~hi ->
    if I.compare lo hi > 0
    then Error.raise_s [%message "int64: crossed bounds" (lo : int64) (hi : int64)];
    let diff = I.sub hi lo in
    if diff = I.of_int64 (Int64.max_value)
    then I.add (I.logand (next_int64 state) (Int64.max_value)) lo
    else if diff >= 0L
    then non_negative_up_to state diff + lo
    else between state ~lo ~hi
*)