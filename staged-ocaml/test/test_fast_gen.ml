open Fast_gen;;
(* module G = Fast_gen.Staged_generator;; *)

open Difftest

module IntTC : TestCase = struct
  type t = int [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.int
  end
end

module IntUniformTC : TestCase = struct
  type t = int [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.int_uniform
  end
end

module IntUniformInclusiveTC : TestCase = struct
  type t = int [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.int_uniform_inclusive ~lo:(G.C.lift (-10000)) ~hi:(G.C.lift 10000)
  end
end

module IntInclusiveTC : TestCase = struct
  type t = int [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.int_inclusive ~lo:(G.C.lift 0) ~hi:(G.C.lift 100)
  end
end

module IntLogUniformInclusiveTC : TestCase = struct
  type t = int [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.int_log_uniform_inclusive ~lo:(G.C.lift 0) ~hi:(G.C.lift 100)
  end
end

module IntLogInclusiveTC : TestCase = struct
  type t = int [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.int_log_inclusive ~lo:(G.C.lift 0) ~hi:(G.C.lift 100)
  end
end

module FloatExTC : TestCase = struct
  type t = float [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.float_uniform_exclusive ~lo:(G.C.lift 0.0) ~hi:(G.C.lift 1.0)
  end
end

module FloatInTC : TestCase = struct
  type t = float [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.float_uniform_inclusive ~lo:(G.C.lift 0.0) ~hi:(G.C.lift 1.0)
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
    let i = G.int
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
    let int0 = int
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
              let%bind x = int in
              let%bind xs =  with_size ~size_c:(pred cs) @@ recurse go (lift ()) in
              return (cons x xs)
            );
          ]
      )
  end
end

module IntUIList : TestCase = struct
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
              let%bind x = int_uniform_inclusive ~lo:(lift 0) ~hi:(lift 100) in
              let%bind xs =  with_size ~size_c:(pred cs) @@ recurse go (lift ()) in
              return (cons x xs)
            );
          ]
      )
  end
end

module BoolList : TestCase = struct
  type t = bool list [@@deriving eq, show]
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
              let%bind x = bool in
              let%bind xs =  with_size ~size_c:(pred cs) @@ recurse go (lift ()) in
              return (cons x xs)
            );
          ]
      )
  end
end

module ConstFalseListCombinator : TestCase = struct
  type t = bool list [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
    open G
    open G.Let_syntax
    open C
    let gen = G.list (G.return (lift false))
  end
end

module SizeListCombinator : TestCase = struct
  type t = int list [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
    open G
    open G.Let_syntax
    open C
    let gen = G.list G.size
  end
end

module BoolListCombinator : TestCase = struct
  type t = bool list [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
    open G
    open G.Let_syntax
    open C
    let gen = G.list G.bool 
  end
end

module BoolListListCombinator : TestCase = struct
  type t = bool list list [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
    open G
    open G.Let_syntax
    open C
    let gen = G.list (G.list G.bool)
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
           bind (int) ~f:(fun x ->
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
    let gen = int
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
      bind (int_uniform_inclusive ~lo:(lift (-10)) ~hi:(lift 10)) ~f:(fun x ->
        bind (int_uniform_inclusive ~lo:x ~hi:(lift 20)) ~f:(fun y ->
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

module OfListDynTC : TestCase = struct
  type t = int [@@deriving eq, show]
  module F (G : Generator_intf.S) = struct
    open G
    open Let_syntax
    open C
    let gen = of_list_dyn (cons (lift 1) (cons (lift 2) (cons (lift 3) cnil)))
  end
end

let qc_cfg = { Base_quickcheck.Test.default_config with
  seed = Base_quickcheck.Test.Config.Seed.Nondeterministic
}

module G_Bq = Bq_generator
module G_SR = Staged_generator.MakeStaged(Sr_random)
module G_C = Staged_generator.MakeStaged(C_random)
module G_C_SR = Staged_generator.MakeStaged(C_sr_dropin_random)
module G_Lehmer = Staged_generator.MakeStaged(Lehmer_random)

module Bm = Benchmark

(* let () =
  let module TC = IntTC in
  let module M1 = TC.F(G_Bq) in
  let module M2 = TC.F(G_SR) in
  let module M3 = TC.F(G_C) in
  let module M4 = TC.F(G_C_SR) in
  let module M5 = TC.F(G_Lehmer) in
  let g1 = M1.gen in
  let g2 = G_SR.jit M2.gen in
  let g3 = G_C.jit M3.gen in
  let g4 = G_C_SR.jit M4.gen in
  let g5 = G_Lehmer.jit M5.gen in
  Benchmark.bm ~bench_name:"Int list" ~named_gens:[
    "BQ",g1;
    "SR",g2;
    "C", g3;
    "CSR", g4;
    "Lehmer", g5
  ] ~sizes:[10;50;100;1000] ~seeds:[100] ~num_calls:10000 *)


(* let () =
  let module TC = IntUIList in
  let module M1 = TC.F(G_Bq) in
  let module M2 = TC.F(G_SR) in
  let module M3 = TC.F(G_C_SR) in
  let module M4 = TC.F(G_C) in
  let g1 = M1.gen in
  let g2 = G_SR.jit M2.gen in
  let g3 = G_C_SR.jit M3.gen in
  let g4 = G_C.jit M4.gen in
  Benchmark.bm ~bench_name:"Int list (uniform inclusive)" ~named_gens:["BQ",g1; "Staged SR",g2; "Staged CSR",g3; "Staged C", g4] ~sizes:[10;50;100] ~seeds:[100] ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.)) *)

  (*
let () =
  let module TC = IntTC in
  let module M1 = TC.F(G_Bq) in
  let module M2 = TC.F(G_SR) in
  let module M3 = TC.F(G_C) in
  let module M4 = TC.F(G_C_SR) in
  let g1 = M1.gen in
  let g2 = G_SR.jit M2.gen in
  let g3 = G_C.jit M3.gen in
  let g4 = G_C_SR.jit M4.gen in
  Benchmark.bm ~bench_name:"int" ~named_gens:["BQ",g1; "Staged SR",g2; "Staged C", g3; "Staged CSR", g4] ~sizes:[10;50;100;1000] ~seeds:[100] ~num_calls:100000
  *)


(* open Bst_benchmark *)
open Stlc_benchmark

(* 
let () =
  let open Alcotest in
  run "Staged Generators" [
    (* "Derived", [derived_testcase] *)
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
      (let open MakeDiffTest(ConstFalseListCombinator)(G_Bq)(G_SR) in alco ~config:qc_cfg "Const False List Combinator Generator");
      (let open MakeDiffTest(SizeListCombinator)(G_Bq)(G_SR) in alco ~config:qc_cfg "Size List Combinator Generator");
      (let open MakeDiffTest(BoolListCombinator)(G_Bq)(G_SR) in alco ~config:qc_cfg "Bool List Combinator Generator");
      (let open MakeDiffTest(BoolListListCombinator)(G_Bq)(G_SR) in alco ~config:qc_cfg "Bool List List Combinator Generator");
      (let open MakeDiffTest(AA)(G_Bq)(G_SR) in alco ~config:qc_cfg "Swing generator");
      (let open MakeDiffTest(BB)(G_Bq)(G_SR) in alco ~config:qc_cfg "Unused bind-to-union");
      (let open MakeDiffTest(OfListDynTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "OfListDyn");
      bst_test;
      stlc_test
    ];
    "RNG Bool Equivalence", [
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ];
    "RNG Int Equivalence", [
      (let open MakeDiffTest(IntTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ];
    "RNG Int Uniform Equivalence", [
      (let open MakeDiffTest(IntUniformTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntUniformTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntUniformTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ];
    "RNG Int Uniform Inclusive Equivalence", [
      (let open MakeDiffTest(IntUniformInclusiveTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntUniformInclusiveTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntUniformInclusiveTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ]
    ;
    "RNG Int Inclusive Equivalence", [
      (let open MakeDiffTest(IntInclusiveTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntInclusiveTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntInclusiveTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
      (let open MakeDiffTest(IntInclusiveTC)(G_C)(G_C_SR) in alco ~config:qc_cfg "C/C_SR");
    ]
    ;
    "RNG Int Log Uniform Inclusive Equivalence", [
      (let open MakeDiffTest(IntLogUniformInclusiveTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntLogUniformInclusiveTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntLogUniformInclusiveTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ]
    ;
    "RNG Int Log Inclusive Equivalence", [
      (let open MakeDiffTest(IntLogInclusiveTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntLogInclusiveTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntLogInclusiveTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ]
    ;
    "RNG Float Exclusive Equivalence", [
      (let open MakeDiffTest(FloatExTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(FloatExTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(FloatExTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ]
    ;
    "RNG Float Inclusive Equivalence", [
      (let open MakeDiffTest(FloatInTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(FloatInTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(FloatInTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ]
    ;
    (* "RNG Equivalence",[
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_C) in alco ~config:qc_cfg "Bool Simple -- Bq/Staged_C");
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "Bool Simple -- Bq/Staged_SR");
      (let open MakeDiffTest(BoolTC)(G_C)(G_SR) in alco ~config:qc_cfg "Bool Simple -- Staged_C/Staged_SR");
      (let open MakeDiffTest(BoolTC)(G_C_SR)(G_C) in alco ~config:qc_cfg "Bool Simple -- Staged_C_SR/Staged_C");
      (let open MakeDiffTest(BoolTC)(G_C_SR)(G_SR) in alco ~config:qc_cfg "Bool Simple -- Staged_C_SR/Staged_SR");
      (* (let open MakeDiffTest(IntTC)(G_Bq)(G_C) in alco ~config:qc_cfg "Int Simple -- Bq/Staged_C"); *)
      (let open MakeDiffTest(IntTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "Int Simple -- Bq/Staged_SR");
      (* (let open MakeDiffTest(IntTC)(G_C)(G_SR) in alco ~config:qc_cfg "Int Simple -- Staged_C/Staged_SR"); *)
      (* (let open MakeDiffTest(IntTC)(G_C_SR)(G_C) in alco ~config:qc_cfg "Int Simple -- Staged_C_SR/Staged_C"); *)
      (* (let open MakeDiffTest(IntTC)(G_C_SR)(G_SR) in alco ~config:qc_cfg "Int Simple -- Staged_C_SR/Staged_SR"); *)
      (* (let open MakeDiffTest(IntLogUniformTC)(G_Bq)(G_C) in alco ~config:qc_cfg "Int LU Simple -- Bq/Staged_C"); *)
      (let open MakeDiffTest(IntLogUniformTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "Int LU Simple -- Bq/Staged_SR");
      (* (let open MakeDiffTest(IntLogUniformTC)(G_C)(G_SR) in alco ~config:qc_cfg "Int LU Simple -- Staged_C/Staged_SR"); *)
      (* (let open MakeDiffTest(IntLogUniformTC)(G_C_SR)(G_C) in alco ~config:qc_cfg "Int LU Simple -- Staged_C_SR/Staged_C"); *)
      (* (let open MakeDiffTest(IntLogUniformTC)(G_C_SR)(G_SR) in alco ~config:qc_cfg "Int LU Simple -- Staged_C_SR/Staged_SR"); *)
      (* (let open MakeDiffTest(FloatTC)(G_Bq)(G_C) in alco ~config:qc_cfg "Float Simple -- Bq/Staged_C"); *)
      (let open MakeDiffTest(FloatTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "Float Simple -- Bq/Staged_SR");
      (let open MakeDiffTest(FloatTC)(G_C)(G_SR) in alco ~config:qc_cfg "Float Simple -- Staged_C/Staged_SR");
      (let open MakeDiffTest(FloatTC)(G_C_SR)(G_C) in alco ~config:qc_cfg "Float Simple -- Staged_C_SR/Staged_C");
      (let open MakeDiffTest(FloatTC)(G_C_SR)(G_SR) in alco ~config:qc_cfg "Float Simple -- Staged_C_SR/Staged_SR");
      (* (let open MakeDiffTest(BB)(G_SR)(G_C) in alco ~config:qc_cfg "Union -- BQ/Staged_C"); *)
    ] *)
  ] *)