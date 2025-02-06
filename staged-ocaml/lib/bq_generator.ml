type 'a t = 'a Base_quickcheck.Generator.t
type 'a c = 'a

let lift x = x
let c_i2f = Float.of_int
let pair x y = (x,y)

let return = Base_quickcheck.Generator.return
let bind = Base_quickcheck.Generator.bind
let choose = Base_quickcheck.Generator.weighted_union
let int ~lo ~hi = Base_quickcheck.Generator.int_uniform_inclusive lo hi
let float ~lo ~hi = Base_quickcheck.Generator.float_uniform_exclusive lo hi
let bool = Base_quickcheck.Generator.bool
let size = Base_quickcheck.Generator.size
let with_size g ~size_c = Base_quickcheck.Generator.with_size ~size:size_c g

let to_qc = fun x -> x
let to_fun g = fun ~size ~random -> Base_quickcheck.Generator.generate g ~size ~random

type ('a,'r) recgen = 'r -> 'a t
let recurse f = f
let recursive (type a) (type r) (x0 : r ) (step : (a,r) recgen -> r -> a t) =
  let rec go x =
    step go x 
  in
  (go x0)