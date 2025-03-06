open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open My_tree;;
open Sexplib0.Sexp_conv;;

module G_SR : sig
    include module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
  end
  
val quickcheck_generator : My_tree.t G_SR.c G_SR.t

val sexp_of_t : t -> Sexplib0.Sexp.t