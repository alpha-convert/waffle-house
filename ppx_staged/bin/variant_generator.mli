open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Sexplib;;
open Sexplib0;;
open My_variant;;

module G_SR : sig
    include module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
  end
  
val quickcheck_generator : My_variant.t G_SR.c G_SR.t

val sexp_of_t : t -> Sexp.t