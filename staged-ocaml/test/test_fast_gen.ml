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

module AA : TestCase = struct
  type t = int * int [@@deriving eq, show]
  module F (G : Generator_intf.GENERATOR) = struct
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
  module F (G : Generator_intf.GENERATOR) = struct
    open G
    open Let_syntax
    open C
    let gen =
      let%bind x = return (lift 100) in
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


let typ_test =
  (* need to pass the path to the CMI files for stlc_impl *)
  let path = "/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte/" in
  let g1 = Stlc_gen_bq.genTyp in
  (* let () = Staged_generator.print Stlc_gen_st.genTyp in *)
  let g2 = Base_quickcheck.Generator.create (Staged_generator.jit ~deps:[path] Stlc_gen_st.genTyp) in
  Difftest.difftest ~config:qc_cfg ~name:"TypTest" (fun v1 v2 -> failwith @@ "BQ: " ^ Typ.show v1 ^ "\nST: " ^ Typ.show v2 ^"\n") Typ.equal g1 g2

let gen_const_test =
  let t0 = Typ.TBool in
  (* need to pass the path to the CMI files for stlc_impl *)
  let path = "/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte/" in
  let g1 = Stlc_gen_bq.genConst t0 in
  (* let () = Staged_generator.print (Stlc_gen_st.genConst .<t0>.) in *)
  let g2 = Base_quickcheck.Generator.create (Staged_generator.jit ~deps:[path] (Stlc_gen_st.genConst .<t0>.)) in
  Difftest.difftest ~config:qc_cfg ~name:"Gen Const Test" (fun v1 v2 -> failwith @@ "BQ: " ^ Expr.show v1 ^ "\nST: " ^ Expr.show v2 ^"\n") Expr.equal g1 g2


let stlc_test =
  (* need to pass the path to the CMI files for stlc_impl *)
  let path = "/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte/" in
  let g1 = Stlc_gen_bq.genExpr in
  let () = Staged_generator.print Stlc_gen_st.genExpr in
  let g2 = Base_quickcheck.Generator.create (Staged_generator.jit ~deps:[path] Stlc_gen_st.genExpr) in
  Difftest.difftest ~config:qc_cfg ~name:"STLC" (fun v1 v2 -> failwith @@ "BQ: " ^ Expr.show v1 ^ "\nST: " ^ Expr.show v2 ^"\n") Expr.equal g1 g2

(* module M = MakeDiffTest(IntList) *)

let () =
  let open Alcotest in
  run "Fusion Equivalence" [
    "DiffTest", [
      (*(let open MakeDiffTest(BindTC) in alco ~config:qc_cfg "Bind Ordering");
      (let open MakeDiffTest(ChooseTC) in alco ~config:qc_cfg "Choose Correctness");
      (let open MakeDiffTest(ChooseBind1) in alco ~config:qc_cfg "Choose with size weights");
      (let open MakeDiffTest(ChooseBind2) in alco ~config:qc_cfg "Choose with bind ordering");
      (let open MakeDiffTest(BoolChoose) in alco ~config:qc_cfg "More choose testing with bools");
      (let open MakeDiffTest(SimpleInt) in alco ~config:qc_cfg "Int Sampling");
      (let open MakeDiffTest(SimpleBool) in alco ~config:qc_cfg "Bool Sampling");
      (let open MakeDiffTest(IntRange) in alco ~config:qc_cfg "Range of ints");
      (let open MakeDiffTest(IntList) in alco ~config:qc_cfg "Int List Generator");
      (let open MakeDiffTest(AA) in alco ~config:qc_cfg "Swing generator");
      *)
      (let open MakeDiffTest(BB) in alco ~config:qc_cfg "BB");
      typ_test;
      gen_const_test;
      stlc_test;
    ]
  ]

