
open Codelib

module G = Fast_gen.Staged_generator;;

let c = G.size

let () = Codelib.print_code Format.std_formatter (G.to_qc c)





let g = G.jit c
let () = print_newline () ; print_int @@ Base_quickcheck.Generator.generate g ~size:5 ~random:(Splittable_random.State.of_int 3)