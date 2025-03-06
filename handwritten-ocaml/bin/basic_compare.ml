open Core;;
open Core_bench;;

module Fake_Bq = struct
  type 'a t = Splittable_random.t -> 'a

  let return (x : 'a) : 'a t = fun _ -> x

  let bind (g : 'a t) (f : 'a -> 'b t) =
    fun sd -> f (g sd) sd
  
  let int lo hi : int t = fun sd -> Splittable_random.int ~lo:lo ~hi:hi sd

  let create (f : Splittable_random.t -> 'a) : 'a t = f
end

let g1 = Fake_Bq.bind (Fake_Bq.int 0 100) (fun x -> Fake_Bq.bind (Fake_Bq.int 0 x) (fun y -> Fake_Bq.return (x,y)))

let g2 = fun sr ->
  let x = Splittable_random.int sr ~lo:0 ~hi:100 in
  let y = Splittable_random.int sr ~lo:0 ~hi:x in
  (x,y)

let main () = Bench.bench 
  ~run_config:(Bench.Run_config.create ~quota:(Bench.Quota.Num_calls 10000) ())
  [
  Bench.Test.create ~name:"bq"(
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () ->  g1 random
  );
  Bench.Test.create ~name:"fused"(
    let random = Splittable_random.create (Random.State.make_self_init ()) in
    fun () ->  g2 random
  );
]