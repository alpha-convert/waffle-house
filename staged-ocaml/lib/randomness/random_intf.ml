open Codelib

module type S = sig
  type t

  val of_int : int -> t

  val bool : t code -> bool code
  val int : t code -> lo:(int code) -> hi:(int code) -> int code
  val float : t code -> lo:(float code) -> hi:(float code) -> float code

  val dep_name : string option

end