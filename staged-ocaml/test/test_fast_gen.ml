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

module IntLogUniformTC : TestCase = struct
  type t = int [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.int_log_uniform_inclusive ~lo:(G.C.lift 0) ~hi:(G.C.lift 100)
  end
end

module FloatTC : TestCase = struct
  type t = float [@@deriving eq,show]
  module F (G : Generator_intf.S) = struct
    let gen = G.float ~lo:(G.C.lift 0.0) ~hi:(G.C.lift 1.0)
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

module Bm = Benchmark

let () =
  let module TC = IntList in
  let module M1 = TC.F(G_Bq) in
  let module M2 = TC.F(G_C) in
  let module M3 = TC.F(G_SR) in
  let g1 = M1.gen in
  let g2 = G_C.jit M2.gen in
  let g3 = G_SR.jit M3.gen in
  Benchmark.bm ~bench_name:"Int list" ~named_gens:["BQ",g1; "Staged C",g2; "Staged SR", g3] ~sizes:[10;50;100;1000] ~num_calls:5000


let () =
  let module TC = IntUIList in
  let module M1 = TC.F(G_Bq) in
  let module M2 = TC.F(G_SR) in
  let module M3 = TC.F(G_C_SR) in
  let g1 = M1.gen in
  let g2 = G_SR.jit M2.gen in
  let g3 = G_C_SR.jit M3.gen in
  Benchmark.bm ~bench_name:"Int list (uniform inclusive)" ~named_gens:["BQ",g1; "Staged SR",g2; "Staged CSR", g3] ~sizes:[10;50;100;1000] ~num_calls:5000

let () =
  let module TC = IntTC in
  let module M1 = TC.F(G_Bq) in
  let module M2 = TC.F(G_C) in
  let g1 = M1.gen in
  let g2 = G_C.jit M2.gen in
  let () = G_C.print M2.gen in
  Benchmark.bm ~bench_name:"int" ~named_gens:["BQ",g1; "Staged C",g2] ~sizes:[10;50;100;1000] ~num_calls:5000



let path = "/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte/"

(* let stlc_test =
  let g1 = Stlc_gen_bq.genExpr in
  let g2 = G_SR.jit ~extra_cmi_paths:[path] Stlc_gen_st.genExpr in
  Difftest.difftest ~config:qc_cfg ~name:"STLC" (fun v1 v2 -> failwith @@ "BQ: " ^ Expr.show v1 ^ "\nST: " ^ Expr.show v2 ^"\n") Expr.equal g1 g2

let g1 = Base_quickcheck.Generator.create
(fun ~size:size_26 ->
   fun ~random:random_27 ->
     let t_28 = Obj.magic 0 in
     let t_50 =
       let rec go_29 x_30 ~size:size_31  ~random:random_32  =
         if size_31 = 0
         then
           let t_44 = 0. +. 1. in
           let t_45 = Base.Float.one_ulp `Up 0. in
           let t_46 = Base.Float.one_ulp `Down t_44 in
           let t_47 = Splittable_random.float random_32 ~lo:t_45 ~hi:t_46 in
           let t_48 = (Stdlib.Float.compare t_47 1.) <= 0 in
           (if t_48
            then []
            else
              (let t_49 = t_47 -. 1. in
               Stdlib.failwith "Fell of the end of pick list"))
         else
           (let t_33 = 0. +. 1. in
            let t_34 = t_33 +. 100. in
            let t_35 = Base.Float.one_ulp `Up 0. in
            let t_36 = Base.Float.one_ulp `Down t_34 in
            let t_37 = Splittable_random.float random_32 ~lo:t_35 ~hi:t_36 in
            let t_38 = (Stdlib.Float.compare t_37 1.) <= 0 in
            if t_38
            then []
            else
              (let t_39 = t_37 -. 1. in
               let t_40 = (Stdlib.Float.compare t_39 100.) <= 0 in
               if t_40
               then
                 let t_42 =
                   go_29 (Obj.magic 0) ~size:(size_31 - 1)
                     ~random:random_32 in
                 let t_43 = Splittable_random.bool random_32 in
                 (t_43 :: t_42)
               else
                 (let t_41 = t_39 -. 100. in
                  Stdlib.failwith "Fell of the end of pick list"))) in
       go_29 t_28 ~size:size_26 ~random:random_27 in
     t_50)

let g2 =
      let rec quikckcheck_generator =
        lazy
          (let quickcheck_generator =
             Ppx_quickcheck_runtime.Base_quickcheck.Generator.of_lazy
               quickcheck_generator in
           ignore quickcheck_generator;
           (let _pair__011_ =
              (1.,
                (Ppx_quickcheck_runtime.Base_quickcheck.Generator.create
                   (fun ~size:_size__015_ ->
                      fun ~random:_random__016_ -> [])))
            and _pair__012_ =
              (100.,
                (Ppx_quickcheck_runtime.Base_quickcheck.Generator.bind
                   Ppx_quickcheck_runtime.Base_quickcheck.Generator.size
                   ~f:(fun _size__008_ ->
                         Ppx_quickcheck_runtime.Base_quickcheck.Generator.with_size
                           ~size:(Ppx_quickcheck_runtime.Base.Int.pred
                                    _size__008_)
                           (Ppx_quickcheck_runtime.Base_quickcheck.Generator.create
                              (fun ~size:_size__013_ ->
                                 fun ~random:_random__014_ ->
                                   
                                     ((Ppx_quickcheck_runtime.Base_quickcheck.Generator.generate
                                        Base_quickcheck.quickcheck_generator_bool
                                         ~size:_size__013_
                                         ~random:_random__014_) ::
                                       (Ppx_quickcheck_runtime.Base_quickcheck.Generator.generate
                                          quickcheck_generator
                                          ~size:_size__013_
                                          ~random:_random__014_))))))) in
            let _gen__009_ =
              Ppx_quickcheck_runtime.Base_quickcheck.Generator.weighted_union
                [_pair__011_]
            and _gen__010_ =
              Ppx_quickcheck_runtime.Base_quickcheck.Generator.weighted_union
                [_pair__011_; _pair__012_] in
            Ppx_quickcheck_runtime.Base_quickcheck.Generator.bind
              Ppx_quickcheck_runtime.Base_quickcheck.Generator.size
              ~f:(function | 0 -> _gen__009_ | _ -> _gen__010_))) in
      Ppx_quickcheck_runtime.Base_quickcheck.Generator.of_lazy
        quickcheck_generator

let bl2s xs = "[" ^ (String.concat "," (List.map Bool.to_string xs)) ^ "]"

let derived_testcase = Difftest.difftest ~config:qc_cfg ~name:"STLC" (fun v1 v2 -> failwith @@ "BQ: " ^ bl2s v1 ^ "\nST: " ^ bl2s v2 ^"\n") (List.equal Bool.equal) g1 g2 *)
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
            (* stlc_test; *)
    ];
    "RNG Bool Equivalence", [
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(BoolTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ];
    "RNG Int Equivalence", [
      (let open MakeDiffTest(IntTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (* (let open MakeDiffTest(IntTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR"); *)
    ];
    "RNG Int Uniform Equivalence", [
      (let open MakeDiffTest(IntUniformTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntUniformTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntUniformTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ];
    "RNG Int Uniform Inclusive Equivalence", [
      (let open MakeDiffTest(IntUniformInclusiveTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntUniformInclusiveTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntUniformInclusiveTC)(G_SR)(G_C) in alco ~config:qc_cfg "SR/C");
      (let open MakeDiffTest(IntUniformInclusiveTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
    ]
    ;
    "RNG Int Inclusive Equivalence", [
      (let open MakeDiffTest(IntInclusiveTC)(G_Bq)(G_SR) in alco ~config:qc_cfg "SR");
      (let open MakeDiffTest(IntInclusiveTC)(G_Bq)(G_C) in alco ~config:qc_cfg "C");
      (let open MakeDiffTest(IntInclusiveTC)(G_Bq)(G_C_SR) in alco ~config:qc_cfg "C_SR");
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
