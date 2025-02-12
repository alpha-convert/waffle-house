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


  val return : 'a -> 'a t
  val bind : 'a t -> f:('a -> 'b t) -> 'b t
  val map : f:('a -> 'b) -> 'a t -> 'b t
  val map2 : f:('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t
  val join : 'a t t -> 'a t

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( >>| ) : 'a t -> ('a -> 'b) -> 'b t

  val int : lo:(int c) -> hi:(int c) -> int c t
  val bool : bool c t

  val weighted_union : (float c * 'a c t) list -> 'a c t
  val union : 'a c t list -> 'a c t
  val of_list : 'a list -> 'a t

  val size : int c t
  val with_size : 'a t -> size_c:(int c) -> 'a t

  val to_fun : 'a c t -> (size:int -> random:Splittable_random.State.t -> 'a) c

  type ('a,'r) recgen
  val recurse : ('a,'r) recgen -> 'r c -> 'a c t
  val recursive : 'r c -> (('a,'r) recgen -> 'r c -> 'a c t) -> 'a c t

end