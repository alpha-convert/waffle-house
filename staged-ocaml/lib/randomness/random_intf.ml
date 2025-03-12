open Codelib

module type S = sig
  type t

  val bool : t code -> bool code
  val int : t code -> lo:(int code) -> hi:(int code) -> int code
  val int_unchecked : t code -> lo:(int code) -> hi:(int code) -> int code
  val float : t code -> lo:(float code) -> hi:(float code) -> float code
  val float_unchecked : t code -> lo:(float code) -> hi:(float code) -> float code

  val one_ulp : dir:([`Up | `Down]) -> float code -> float code

  module Log_uniform : sig
    val int : t code -> lo:(int code) -> hi:(int code) -> int code
  end

  (* convert an existing splittalbe random seed into a customr random seed. 
     Mutating the result of `of_sr` may or may not mutate the corresponding SR random value.
     In c_sr_dropin and sr_random, it does --- the former returns a mutable "view" into the SR, the latter is the identity.
     C_random's implementation of of_sr *copies the seed* and creates a new value. Sampling from this
     does *not* mutate the passed SR state.
     To propogate those changes back into the SR, we call repopulate_SR. This is a no-op for c_sr_dropin and sr_random.
  *)
  val of_sr : Splittable_random.State.t code -> t code
  val repopulate_sr : t code -> Splittable_random.State.t code -> unit code

  val dep_paths : string list
end