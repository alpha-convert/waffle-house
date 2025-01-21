open Cmt_format

let () =
  let filename = Sys.argv.(1) in
  match read_cmt filename with
  | cmt_info -> Printcmt.print_cmt cmt_info
  | exception ex -> Printf.eprintf "Error: %s\n" (Printexc.to_string ex)
