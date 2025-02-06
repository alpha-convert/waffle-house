open Fast_gen;;
(* module G = Fast_gen.Staged_generator;; *)

open Difftest

module BindTC : TestCase = struct
  type t = int * int [@@deriving eq]
  (* let eq (x,y) (x',y') = Int.equal x x' && Int.equal y y' *)
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



module BDT = MakeDiffTest(BindTC)
let () =
  let open Alcotest in
  run "Fusion Equivalence" [
    "DiffTest", [
      BDT.alco "Bind"
    ]
  ]
(* BDT.run () *)




(* let () = G.print g *)