
type state

external of_int : Int64.t -> state = "of_int"

external perturb : state -> Int64.t -> unit = "perturb"

external int : state -> int = "intv"
external bool : state -> bool = "bool"