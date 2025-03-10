(*
The external functions need to be included in their own .ml file, so that there is a
*separate* cmi from the C_Random.ml that can be linked in at JIT-time.
Otherwise, MetaOCaml tries to serialize these external functions and gets confused.
*)

type t

external int_c_unchecked : t -> int -> int -> int = "int_c_unchecked"
external int_c_log_uniform : t -> int -> int -> int = "int_c_log_uniform"
external bool_c : t -> bool = "bool_c"
external float_c_unchecked : t -> (float [@unboxed]) -> (float [@unboxed])-> (float [@unboxed])= "float_c_unchecked" "float_c_unchecked_unboxed"
external create : int64 -> int64 -> t = "create_state"

external one_ulp_up : float -> float = "one_ulp_up_c" "one_ulp_up_c_unboxed" [@@unboxed] [@@noalloc]
external one_ulp_down : float -> float = "one_ulp_down_c" "one_ulp_down_c_unboxed" [@@unboxed] [@@noalloc]
