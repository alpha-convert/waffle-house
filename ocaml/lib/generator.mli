type 'a t

val return : 'a -> 'a t
val bind : 'a t -> f:('a -> 'b t) -> 'b t

val to_qc : ('a Code.t) t -> ('a Base_quickcheck.Generator.t) Code.t