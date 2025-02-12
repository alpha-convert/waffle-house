module type S = sig
  type t

  val of_int : int -> t

  val bool : t -> bool
  val int : t -> lo:int -> hi:int -> int
  val float : t -> lo:float -> hi:float -> float

end