open Fast_gen;;
(* module G = Fast_gen.Staged_generator;; *)

open Difftest

module BindTC : TestCase = struct
  type t = int * int
  let eq (x,y) (x',y') = Int.equal x x' && Int.equal y y'
  module F (G : Generator_intf.GENERATOR) = struct
    let i = G.int ~lo:(G.lift 0) ~hi:(G.lift 100)
    let gen =
      G.bind i ~f:(fun nc ->
        G.bind i ~f:(fun nc' ->
          G.return (G.pair nc' nc)
        )
      )
  end
end

(* module BDT = MakeDiffTest(BindTC) *)
(* let () = BDT.run () *)


module ChooseTC : TestCase = struct
  type t = int
  let eq x y = Int.equal x y
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    let gen = 
    bind size ~f:(fun nc ->
      choose [
        (lift 1., return (lift 500));
        (lift 2., return (lift 1000));
        (lift 1., return (lift 100));
      ]
    )
  end
end

module DT = MakeDiffTest(ChooseTC)
let () = DT.run ()

(* let () = G.print g *)