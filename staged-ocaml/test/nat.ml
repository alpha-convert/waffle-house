include Core;;
module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
module G_C = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_random)
module G_CSR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)

let staged_quickcheck_generator_sr_t =
    (G_SR.bind G_SR.int ~f:(fun  i -> G_SR.return (G_SR.C.modulus i 1000)))

let staged_quickcheck_generator_c_t =
    (G_C.bind G_C.int ~f:(fun  i -> G_C.return (G_C.C.modulus i 1000)))

let staged_quickcheck_generator_csr_t =
    (G_CSR.bind G_CSR.int ~f:(fun  i -> G_CSR.return (G_CSR.C.modulus i 1000)))
    
let quickcheck_generator_int_new = let open Base_quickcheck.Generator in
  bind int ~f:(fun i -> return (i mod 1000))

type t = int [@quickcheck.generator quickcheck_generator_int_new] [@@deriving sexp, quickcheck, eq, show]

let to_string x = Int.to_string x