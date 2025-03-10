type t = Splittable_random.State.t

open Splittable_random


let int st ~lo ~hi = .< Splittable_random.int .~st ~lo:.~lo ~hi:.~hi >.
let int_unchecked st ~lo ~hi = .< Splittable_random.int .~st ~lo:.~lo ~hi:.~hi >.
let bool st = .< bool .~st >.
let float st ~lo ~hi = .< Splittable_random.float .~st ~lo:.~lo ~hi:.~hi >.
let float_unchecked st ~lo ~hi = .< Splittable_random.float .~st ~lo:.~lo ~hi:.~hi >.

let one_ulp ~dir x = .< Base.Float.one_ulp dir .~x >.

module Log_uniform = struct
  let int st ~lo ~hi = .< Log_uniform.int .~st ~lo:.~lo ~hi:.~hi >.
end

let dep_paths = List.map Util.run_ocamlfind_query ["splittable_random";"base_quickcheck";"base"]

let of_sr x = x