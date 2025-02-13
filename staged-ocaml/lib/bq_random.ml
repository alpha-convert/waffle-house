type t = Splittable_random.State.t

open Splittable_random

let int st ~lo ~hi = .< int .~st ~lo:.~lo ~hi:.~hi >.
let bool st = .< bool .~st >.
let float st ~lo ~hi = .< float .~st ~lo:.~lo ~hi:.~hi >.
let of_int = State.of_int

let dep_name = Some "splittable_random"