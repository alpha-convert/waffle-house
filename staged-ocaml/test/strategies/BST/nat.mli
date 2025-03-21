type t = int [@@deriving sexp, quickcheck]

module G_SR : module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
module G_C : module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_random)
module G_CSR : module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)

val staged_quickcheck_generator_sr_t : int G_SR.c -> t G_SR.c G_SR.t

val staged_quickcheck_generator_c_t : int G_C.c -> t G_C.c G_C.t

val staged_quickcheck_generator_csr_t : int G_CSR.c -> t G_CSR.c G_CSR.t

val quickcheck_generator_parameterized: int -> int Base_quickcheck.Generator.t 

val to_string : t -> string