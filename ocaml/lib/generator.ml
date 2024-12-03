open Core;;

type 'a t = (size:(int Code.t) -> random:(Splittable_random.State.t Code.t) -> 'a Codegen.t)
