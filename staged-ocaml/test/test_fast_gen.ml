open Fast_gen;;
(* module G = Fast_gen.Staged_generator;; *)

open Difftest

module FloatTC : TestCase = struct
  type t = float [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.float (G.C.lift 0.0) (G.C.lift 1.0)
  end
end


module BoolTC : TestCase = struct
  type t = bool [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.bool
  end
end

module BindOrder : TestCase = struct
  type t = int * int [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
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
  module F (G : Generator_intf.S) = struct
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
  module F (G : Generator_intf.S) = struct
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
  module F (G : Generator_intf.S) = struct
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
  module F (G : Generator_intf.S) = struct
    open G
    open G.Let_syntax
    open C
    let gen = 
      recursive (lift ()) (fun go _ ->
        let%bind cs = size in
          weighted_union [
            (lift 1., return (lift []));
            (i2f cs ,
              let%bind x = int ~lo:(lift 0) ~hi:cs in
              let%bind xs =  with_size ~size_c:(pred cs) @@ recurse go (lift ()) in
              return (cons x xs)
            );
          ]
      )
  end
end

module BoolChoose : TestCase = struct
  type t = bool * int [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
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
  module F (G : Generator_intf.S) = struct
    open G
    open C
    let gen = int ~lo:(lift 0) ~hi:(lift 100)
  end
 end
 
 module SimpleBool : TestCase = struct
  type t = bool [@@deriving eq, show] 
  module F (G : Generator_intf.S) = struct
    open G
    open C
    let gen = bool
  end
 end

 module IntRange : TestCase = struct
  type t = int * int [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
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

module AA : TestCase = struct
  type t = int * int [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
    open G
    open C
    let gen =
      bind (weighted_union [lift 1.0, return (lift 9); lift 1.0, return (lift 100)]) ~f:(fun x ->
       weighted_union [
        (lift 1.0, return @@ pair x (lift 1));
        (lift 1.0, (return @@ pair (lift 2) x));
       ] 
      )
  end
end

module BB : TestCase = struct
  type t = int [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
    open G
    open Let_syntax
    open C
    let gen =
      let%bind _ = return (lift 100) in
      union [
        return (lift 100);
        return (lift 102);
      ]
  end
end

open Stlc_impl
open Stlc_gen_bq
open Stlc_gen_st

let qc_cfg = { Base_quickcheck.Test.default_config with
  seed = Base_quickcheck.Test.Config.Seed.Nondeterministic
}

module G_Bq = Bq_generator
module G_SR = Staged_generator.MakeStaged(Sr_random)
module G_C = Staged_generator.MakeStaged(C_random)
module G_C_SR = Staged_generator.MakeStaged(C_sr_dropin_random)

let path = "/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte/"

let stlc_test =
  let g1 = Stlc_gen_bq.genExpr in
  let g2 = G_SR.jit ~extra_cmi_paths:[path] Stlc_gen_st.genExpr in
  Difftest.difftest ~config:qc_cfg ~name:"STLC" (fun v1 v2 -> failwith @@ "BQ: " ^ Expr.show v1 ^ "\nST: " ^ Expr.show v2 ^"\n") Expr.equal g1 g2

let () =
  let open Alcotest in
  run "Staged Generators" [
    "Effect Ordering", [
      (let open MakeDiffTest(BindOrder)(G_Bq)(G_SR) in alco ~config:qc_cfg "Bind Ordering Staging");
      (let open MakeDiffTest(ChooseTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "Choose Correctness");
      (let open MakeDiffTest(ChooseBind1)(G_Bq)(G_SR) in alco ~config:qc_cfg "Choose with size weights");
      (let open MakeDiffTest(ChooseBind2)(G_Bq)(G_SR) in alco ~config:qc_cfg "Choose with bind ordering");
      (let open MakeDiffTest(BoolChoose)(G_Bq)(G_SR) in alco ~config:qc_cfg "More choose testing with bools");
      (let open MakeDiffTest(SimpleInt)(G_Bq)(G_SR) in alco ~config:qc_cfg "Int Sampling");
      (let open MakeDiffTest(SimpleBool)(G_Bq)(G_SR) in alco ~config:qc_cfg "Bool Sampling");
      (let open MakeDiffTest(IntRange)(G_Bq)(G_SR) in alco ~config:qc_cfg "Range of ints");
      (let open MakeDiffTest(IntList)(G_Bq)(G_SR) in alco ~config:qc_cfg "Int List Generator");
      (let open MakeDiffTest(AA)(G_Bq)(G_SR) in alco ~config:qc_cfg "Swing generator");
      (let open MakeDiffTest(BB)(G_Bq)(G_SR) in alco ~config:qc_cfg "Unused bind-to-union");
      
      (* stlc_test; *)
    ];
    "RNG Equivalence",[
      (let open MakeDiffTest(FloatTC)(G_Bq)(G_C) in alco ~config:qc_cfg "Float Simple -- Bq/Staged_C");
      (let open MakeDiffTest(FloatTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "Float Simple -- Bq/Staged_SR");
      (let open MakeDiffTest(FloatTC)(G_C)(G_SR) in alco ~config:qc_cfg "Float Simple -- Staged_C/Staged_SR");
      (let open MakeDiffTest(FloatTC)(G_C_SR)(G_C) in alco ~config:qc_cfg "Float Simple -- Staged_C_SR/Staged_C");
      (let open MakeDiffTest(BB)(G_SR)(G_C) in alco ~config:qc_cfg "Union -- BQ/Staged_C");
    ]
  ]
