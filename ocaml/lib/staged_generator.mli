type 'a t

val return : 'a -> 'a t
val bind : 'a t -> f:('a -> 'b t) -> 'b t

val weighted_union : ((float Code.t) * 'a t) list -> 'a t
val with_size : 'a t -> size:(int Code.t) -> 'a t
val size : int Code.t

val to_qc : ('a Code.t) t -> ('a Base_quickcheck.Generator.t) Code.t