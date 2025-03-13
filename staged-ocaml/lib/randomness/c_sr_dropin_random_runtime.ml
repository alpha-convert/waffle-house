type t = Splittable_random.State.t

external int_c_unchecked : t -> int -> int -> int = "int_c_sr_unchecked" [@@noalloc]
external int_c_log_uniform : t -> int -> int -> int = "int_c_sr_log_uniform" [@@noalloc]
external bool_c : t -> bool = "bool_c_sr" [@@noalloc]
external float_c_unchecked : t -> (float [@unboxed]) -> (float [@unboxed]) -> (float [@unboxed]) = "float_c_sr_unchecked" "float_c_sr_unchecked_unboxed" [@@noalloc]
external create : int64 -> int64 -> t = "create_state"

external one_ulp_up : float -> float = "one_ulp_up_c_sr" "one_ulp_up_c_sr_unboxed" [@@unboxed] [@@noalloc]
external one_ulp_down : float -> float = "one_ulp_down_c_sr" "one_ulp_down_c_sr_unboxed" [@@unboxed] [@@noalloc]
