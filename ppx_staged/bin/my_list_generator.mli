open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open My_list;;

module G_SR : sig
    include module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
  end
  
val quickcheck_generator_my_list : My_list.t G_SR.c G_SR.t

val show : t -> unit