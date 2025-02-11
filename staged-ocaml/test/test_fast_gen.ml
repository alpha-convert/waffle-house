open Fast_gen;;
(* module G = Fast_gen.Staged_generator;; *)

open Difftest

module BindTC : TestCase = struct
  type t = int * int [@@deriving eq, show]
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
  type t = int [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = 
      weighted_union [
        (lift 1., return (lift 500));
        (lift 2., return (lift 1000));
        (lift 1., return (lift 100));
      ]
  end
end

module ChooseBind1 : TestCase = struct
  type t = int [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = 
    bind size ~f:(fun nc ->
      weighted_union [
        (lift 1., return (lift 22));
        (i2f nc, return (lift 1000));
        (lift 1., return (lift 100));
      ]
    )
  end
end

module ChooseBind2 : TestCase = struct
  type t = int * int [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let int0 = int ~lo:(lift 0) ~hi:(lift 100)
    let gen = 
    bind int0 ~f:(fun i ->
      weighted_union [
        (lift 55., bind int0 ~f:(fun j -> return (pair j i)));
        (lift 1., return (pair (lift 1) (lift 2)));
      ]
    )
  end
end

module IntList : TestCase = struct
  type t = int list [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = 
      recursive (lift ()) (
        fun r _ ->
          bind size ~f:(fun cs ->
          weighted_union [
            (lift 1., return (lift []));
            (i2f cs ,
              bind (int ~lo:(lift 0) ~hi:cs) ~f:(fun x ->
                bind (with_size ~size_c:(pred cs) @@ recurse r (lift ())) ~f:(fun xs ->
                  return (cons x xs)
                )
              )
            );
          ]
        )
      )
    
  end
end

module BoolChoose : TestCase = struct
  type t = bool * int [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen =
      bind bool ~f:(fun b ->
        weighted_union [
          (lift 1., return (pair b (lift 42)));
          (lift 2., 
           bind (int ~lo:(lift 0) ~hi:(lift 100)) ~f:(fun x ->
             return (pair b x)
           ))
        ]
      )
  end
end


module SimpleInt : TestCase = struct
  type t = int [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = int ~lo:(lift 0) ~hi:(lift 100)
  end
 end
 
 module SimpleBool : TestCase = struct
  type t = bool [@@deriving eq, show] 
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen = bool
  end
 end

 module IntRange : TestCase = struct
  type t = int * int [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open C
    let gen =
      bind (int ~lo:(lift (-10)) ~hi:(lift 10)) ~f:(fun x ->
        bind (int ~lo:x ~hi:(lift 20)) ~f:(fun y ->
          return (pair x y)
        )
      )
  end
end

let qc_cfg = { Base_quickcheck.Test.default_config with
  seed = Base_quickcheck.Test.Config.Seed.Nondeterministic
}

(* module M = MakeDiffTest(IntList) *)

let () =
  let open Alcotest in
  run "Fusion Equivalence" [
    "DiffTest", [
      (let open MakeDiffTest(BindTC) in alco ~config:qc_cfg "Bind Ordering");
      (let open MakeDiffTest(ChooseTC) in alco ~config:qc_cfg "Choose Correctness");
      (let open MakeDiffTest(ChooseBind1) in alco ~config:qc_cfg "Choose with size weights");
      (let open MakeDiffTest(ChooseBind2) in alco ~config:qc_cfg "Choose with bind ordering");
      (let open MakeDiffTest(BoolChoose) in alco ~config:qc_cfg "More choose testing with bools");
      (let open MakeDiffTest(SimpleInt) in alco ~config:qc_cfg "Int Sampling");
      (let open MakeDiffTest(SimpleBool) in alco ~config:qc_cfg "Bool Sampling");
      (let open MakeDiffTest(IntRange) in alco ~config:qc_cfg "Range of ints");
      (let open MakeDiffTest(IntList) in alco ~config:qc_cfg "Int List Generator");
    ]
  ]