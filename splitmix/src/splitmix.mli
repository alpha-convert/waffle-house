type t

val of_int : int @ local -> t
val copy : t @ local -> t
val create : Core.Random.State.t -> t
val split : t @ local -> t
val bool : t @ local -> bool @ local
val perturb : t @ local -> int -> unit