open Fast_gen;;
(* module G = Fast_gen.Staged_generator;; *)

open Difftest


module Size_TC : TestCase = struct
  type t = int
  let eq x y = Int.equal x y
  module F (G : Generator_intf.GENERATOR) = struct
    let gen = 
    G.bind G.size ~f:(fun nc ->
      G.choose [
        (G.lift 2., G.return 500);
        (G.lift 1., G.return 1000);
        (G.lift 3., G.return 100);
      ]
    )
  end
end

module DT = MakeDiffTest(Size_TC)

let () = DT.run ()

(* let () = G.print g *)