
open Codelib

module G = Fast_gen.Staged_generator;;

let () = Codelib.print_code Format.std_formatter (G.to_qc G.size)