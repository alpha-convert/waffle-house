open Util.Limits;;
include Core;;

module G_SR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.Sr_random)
module G_C = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_random)
module G_CSR = Fast_gen.Staged_generator.MakeStaged(Fast_gen.C_sr_dropin_random)
open Base_quickcheck.Generator

let staged_quickcheck_generator_sr_t k =
    (G_SR.bind G_SR.int ~f:(fun  i -> G_SR.return (G_SR.C.modulus2 i k)))

let staged_quickcheck_generator_c_t k =
    (G_C.bind G_C.int ~f:(fun  i -> G_C.return (G_C.C.modulus2 i k)))

let staged_quickcheck_generator_csr_t k =
    (G_CSR.bind G_CSR.int ~f:(fun  i -> G_CSR.return (G_CSR.C.modulus2 i k)))
    
let quickcheck_generator_int_new = let open Base_quickcheck.Generator in
    bind int ~f:(fun i -> return (i mod bst_type_limits))

let quickcheck_generator_parameterized k = let open Base_quickcheck.Generator in
    bind int ~f:(fun i -> return (i mod k))

type t = int [@quickcheck.generator quickcheck_generator_int_new] [@@deriving sexp, quickcheck]

let to_string x = Int.to_string x