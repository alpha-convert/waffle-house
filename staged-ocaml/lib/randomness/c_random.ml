type t = C_random_runtime.t


let int st ~lo ~hi = .< C_random_runtime.int_c_unchecked .~st .~lo .~hi >.
let bool st = .< C_random_runtime.bool_c .~st >.
let float _ = failwith "unimplemented"

(* THIS IS A HACK!
*)
let dep_paths = ["/home/ubuntu/waffle-house/staged-ocaml/_build/default/lib/.fast_gen.objs/byte/"]

let of_sr sr_t =
  .<
    let o = Obj.repr .~(sr_t) in
    let seed : int64 = Obj.obj (Obj.field o 0) in
    let odd_gamma : int64 = Obj.obj (Obj.field o 1) in
    C_random_runtime.create seed odd_gamma
  >.
