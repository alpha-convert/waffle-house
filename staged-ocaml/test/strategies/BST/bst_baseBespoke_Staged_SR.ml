open Util.Limits
open Type
open Nat;;
module G = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
open G
open Let_syntax
type t = Type.tree [@@deriving sexp, quickcheck]

let staged_code =
  bind (list (map2 (Nat.staged_quickcheck_generator_sr_t (G.C.lift bst_bespoke_limits)) (Nat.staged_quickcheck_generator_sr_t (G.C.lift bst_bespoke_limits)) ~f:(fun x y -> G.C.pair x y)))
  ~f:(fun l -> return .< repeat_insert .~l >.)

let quickcheck_generator = 
  G.jit ~extra_cmi_paths:["/home/ubuntu/etna2/workloads/OCaml/BST/_build/default/lib/.BST.objs/byte"] staged_code
