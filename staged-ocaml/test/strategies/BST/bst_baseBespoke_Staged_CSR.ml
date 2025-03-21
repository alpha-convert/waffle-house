open Util.Limits
open Bst_type
open Nat;;
module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)
open G
open Let_syntax
type t = Bst_type.tree [@@deriving sexp, quickcheck]

let staged_code =
  bind (list (map2 (Nat.staged_quickcheck_generator_csr_t (G.C.lift bst_bespoke_limits)) (Nat.staged_quickcheck_generator_csr_t (G.C.lift bst_bespoke_limits)) ~f:(fun x y -> G.C.pair x y)))
  ~f:(fun l -> return .< repeat_insert .~l >.)

let quickcheck_generator = 
  G.jit ~extra_cmi_paths:["/home/ubuntu/waffle-house/staged-ocaml/_build/default/test/.test_fast_gen.eobjs/byte"] staged_code
