open Stdio
open Fast_gen;;
open Ppx_staged_expander;;
open Rbt;;
open Sexplib0.Sexp_conv;;

module C_SR : sig
    include module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)
  end
  
val staged_quickcheck_generator : Rbt.t C_SR.c C_SR.t