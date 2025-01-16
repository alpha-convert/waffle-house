(** A module for working with natural numbers with custom QuickCheck generator *)

(** The type of natural numbers, represented as [Core.Int.t] *)
type t = Core.Int.t [@@deriving sexp, quickcheck]

(** A QuickCheck generator for natural numbers modulo 128 *)
val quickcheck_generator : t Base_quickcheck.Generator.t

(** A QuickCheck shrinker for natural numbers *)
val quickcheck_shrinker : t Base_quickcheck.Shrinker.t

(** A QuickCheck observer for natural numbers *)
val quickcheck_observer : t Base_quickcheck.Observer.t
