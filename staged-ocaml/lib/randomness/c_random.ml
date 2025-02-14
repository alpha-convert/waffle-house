type t

external int_c_unchecked : t -> int -> int -> int = "int_c_unchecked"
let int_c x lo hi = if lo > hi then failwith "Crossed bounds" else int_c_unchecked x lo hi
external bool_c : t -> bool = "bool_c"
(* external float_c : t -> float -> float -> float = "float_c" *)
external create : int64 -> int64 -> t = "create_state"

let golden_gamma = 0x9e37_79b9_7f4a_7c15L

let int st ~lo ~hi = .< int_c .~st .~lo .~hi >.
let bool st = .< bool_c .~st >.
let float _ = failwith "unimplemented"
let of_int x = create (Int64.of_int x) golden_gamma

let dep_name = None

external print : t -> unit = "print"