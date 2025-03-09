type t = Splittable_random.State.t

external int_c_unchecked : t -> int -> int -> int = "int_c_sr_unchecked"
external bool_c : t -> bool = "bool_c_sr"
external float_c_unchecked : t -> float -> float -> (float [@unboxed]) = "float_c_sr_unchecked" "float_c_sr_unchecked_unboxed"
external create : int64 -> int64 -> t = "create_state"
