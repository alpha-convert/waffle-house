open Codegen_lib.Let_syntax;;

type 'a t = RandGen of (size_c:((* int *) Ppxlib.expression) -> random_c:((* Splittable_random.State.t *) Ppxlib.expression) -> 'a Codegen_lib.t)
type 'a recgen = (* (unit -> 'a Core.Quickcheck.Generator.t) *) Ppxlib.expression

let return x = RandGen (fun ~size_c:_ ~random_c:_ -> Codegen_lib.return x)

let bind (RandGen r) ~f = RandGen (fun ~size_c ~random_c ->
  (* TODO: I think we need a let-insertion here. *)
  let%bind a = r ~size_c ~random_c in
  let (RandGen r') = f a in
  r' ~size_c ~random_c
)

let choose ~loc ((w1,(RandGen g1)) : (* int *) Ppxlib.expression * 'a t) ((w2,(RandGen g2)) : (* int *) Ppxlib.expression * 'a t) : 'a t = RandGen (
  fun ~size_c ~random_c ->
    let%bind rand = Codegen_lib.gen_let ~loc [%expr Splittable_random.int [%e random_c] ~lo:0 ~hi:([%e w1] + [%e w2]) ] in
    Codegen_lib.gen_if ~loc [%expr [%e rand] < [%e w1]] ~tt:(g1 ~size_c ~random_c) ~ff:(g2 ~size_c ~random_c)
)

let with_size (RandGen f) ~size_c =
  RandGen (fun ~size_c:_ ~random_c -> f ~size_c:size_c ~random_c)

let size = RandGen (fun ~size_c ~random_c:_ -> Codegen_lib.return size_c)

let gen_if ~loc b (RandGen f) (RandGen g) = RandGen (
  fun ~size_c  ~random_c ->
    Codegen_lib.gen_if ~loc b ~tt:(f ~size_c ~random_c) ~ff:(g ~size_c ~random_c)
)

let recurse (gc : Ppxlib.expression ) : Ppxlib.expression t = 
  RandGen (fun ~size_c ~random_c -> 
    let loc = !Ast_helper.default_loc in
    Codegen_lib.return (
      Ast_helper.Exp.apply ~loc
        (Ast_helper.Exp.ident ~loc {txt = Longident.Ldot (Longident.Ldot (Longident.Lident "Core", "Quickcheck"), "Generator.generate"); loc})
        [ (Labelled "size", size_c)
        ; (Labelled "random", random_c)
        ; (Nolabel, Ast_helper.Exp.apply ~loc (gc) [Nolabel, Ast_helper.Exp.construct ~loc (Location.mkloc (Longident.Lident "()") loc) None])
        ]
    )
  )