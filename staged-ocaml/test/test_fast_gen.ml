open Fast_gen;;
(* module G = Fast_gen.Staged_generator;; *)

open Difftest

module BindTC : TestCase = struct
  type t = int * int [@@deriving eq]
  module F (G : Generator_intf.GENERATOR) = struct
    let i = G.int ~lo:(G.C.lift 0) ~hi:(G.C.lift 100)
    let gen =
      G.bind i ~f:(fun nc ->
        G.bind i ~f:(fun nc' ->
          G.return (G.C.pair nc' nc)
        )
      )
  end
end

module ChooseTC : TestCase = struct
  type t = int [@@deriving eq]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = 
      choose [
        (lift 1., return (lift 500));
        (lift 2., return (lift 1000));
        (lift 1., return (lift 100));
      ]
  end
end

module ChooseBind1 : TestCase = struct
  type t = int [@@deriving eq]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = 
    bind size ~f:(fun nc ->
      choose [
        (lift 1., return (lift 22));
        (i2f nc, return (lift 1000));
        (lift 1., return (lift 100));
      ]
    )
  end
end

let qc_cfg = { Base_quickcheck.Test.default_config with
  seed = Base_quickcheck.Test.Config.Seed.Nondeterministic
}

let () =
  let open Alcotest in
  run "Fusion Equivalence" [
    "DiffTest", [
      (let open MakeDiffTest(BindTC) in alco ~config:qc_cfg "Bind Ordering");
      (let open MakeDiffTest(ChooseTC) in alco ~config:qc_cfg "Choose Correctness");
      (let open MakeDiffTest(ChooseBind1) in alco ~config:qc_cfg "Choose with size weights");
    ]
  ]