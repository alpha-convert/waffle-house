open Util.Limits
open Type
open Nat;;
module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)
open G
open Let_syntax
type t = Type.tree [@@deriving sexp, quickcheck]

let staged_code =
  bind (list (map2 (Nat.staged_quickcheck_generator_csr_t (G.C.lift 1000)) (Nat.staged_quickcheck_generator_csr_t (G.C.lift 1000)) ~f:(fun x y -> G.C.pair x y)))
  ~f:(fun l -> return .< repeat_insert .~l >.)

let make_quickcheck_generator () =
  G.jit ~extra_cmi_paths:["/ff_artifact/artifact/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte"; "/ff_artifact/artifact/waffle-house/staged-ocaml/_build/default/test/strategies/BST/.BST.objs/byte"] staged_code

let quickcheck_generator = make_quickcheck_generator ()
