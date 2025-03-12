type t = int [@@deriving sexp, quickcheck, eq, show]

module G_SR : module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
module G_C : module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_random)
module G_CSR : module type of Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)

val staged_quickcheck_generator_sr_t : t G_SR.c G_SR.t
    (* (G_SR.bind G_SR.int ~f:(fun  i -> G_SR.return .<.~i mod 1000>.)) *)

val staged_quickcheck_generator_c_t : t G_C.c G_C.t

val staged_quickcheck_generator_csr_t : t G_CSR.c G_CSR.t


val to_string : t -> string