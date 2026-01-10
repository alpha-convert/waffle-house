type t = C_random_runtime.t


let int st ~lo ~hi = .< if Base.Int.compare .~lo .~hi > 0 then failwith "Crossed bounds!" else C_random_runtime.int_c_unchecked .~st .~lo .~hi >.
let int_unchecked st ~lo ~hi = .< C_random_runtime.int_c_unchecked .~st .~lo .~hi >.
let bool st = .< C_random_runtime.bool_c .~st >.

let float st ~(lo : float Codelib.code) ~hi = .<
  if Base.Float.compare .~lo .~ hi > 0 then failwith "Crossed bounds!" else
  if (not (Float.is_finite .~lo && Float.is_finite .~hi)) then failwith "Infite floats" else
  C_random_runtime.float_c_unchecked .~st .~lo .~hi
>.

let float_unchecked st ~(lo : float Codelib.code) ~hi = .<
  C_random_runtime.float_c_unchecked .~st .~lo .~hi
>.

let one_ulp ~dir x =
  match dir with
  | `Up -> .< C_random_runtime.one_ulp_up .~x >.
  | `Down -> .< C_random_runtime.one_ulp_down .~x >.

module Log_uniform = struct
  let int st ~lo ~hi = .< C_random_runtime.int_c_log_uniform .~st .~lo .~hi >.
end

(* THIS IS A HACK!
*)
let dep_paths = ["/ff_artifact/artifact/waffle-house/staged-ocaml/_build/default/lib/.fast_gen.objs/byte/"]

let of_sr sr_t =
  .<
    let o = Obj.repr .~(sr_t) in
    let seed : int64 = Obj.obj (Obj.field o 0) in
    let odd_gamma : int64 = Obj.obj (Obj.field o 1) in
    C_random_runtime.create seed odd_gamma
  >.

let repopulate_sr t t_sr =
  .<
    C_random_runtime.repopulate .~t .~t_sr
  >.