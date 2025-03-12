type t = Splittable_random.State.t

external int_unchecked : t -> int -> int -> int = "int_lehmer_unchecked"
external int_log_uniform : t -> int -> int -> int = "int_lehmer_log_uniform"
external bool : t -> bool = "bool_lehmer"
external float_unchecked : t -> (float [@unboxed]) -> (float [@unboxed])-> (float [@unboxed])= "float_lehmer_unchecked" "float_lehmer_unchecked_unboxed"

external repopulate : t -> Splittable_random.State.t -> unit = "repopulate_lehmer"