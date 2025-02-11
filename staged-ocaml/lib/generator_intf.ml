module type C_INTF = sig
  type 'a t
  val lift : 'a -> 'a t
  val i2f : Int.t t -> Float.t t
  val pair : 'a t -> 'b t -> ('a * 'b) t
  val pred : Int.t t -> Int.t t
  val cons : 'a t -> 'a list t -> 'a list t
end
module type GENERATOR = sig
  type 'a t
  module C : C_INTF
  type 'a c = 'a C.t


  val return : 'a c -> 'a t
  val bind : 'a t -> f:('a c -> 'b t) -> 'b t
  val map : f:('a c -> 'b c) -> 'a t -> 'b t
  val map2 : f:('a c -> 'b c -> 'c c) -> 'a t -> 'b t -> 'c t

  val ( >>= ) : 'a t -> ('a c -> 'b t) -> 'b t
  val ( >>| ) : 'a t -> ('a c -> 'b c) -> 'b t


  val int : lo:(int c) -> hi:(int c) -> int t
  val bool : bool t

  val weighted_union : (float c * 'a t) list -> 'a t
  val union : 'a t list -> 'a t
  val of_list : 'a c list -> 'a t

  val size : int t
  val with_size : 'a t -> size_c:(int c) -> 'a t

  val to_fun : 'a t -> (size:int -> random:Splittable_random.State.t -> 'a) c

  type ('a,'r) recgen
  val recurse : ('a,'r) recgen -> 'r c -> 'a t
  val recursive : 'r c -> (('a,'r) recgen -> 'r c -> 'a t) -> 'a t
end