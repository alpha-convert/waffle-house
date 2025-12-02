open Core

let time_compilation name f =
  let start = Time_ns.now () in
  let result = f () in
  let elapsed = Time_ns.diff (Time_ns.now ()) start in
  Printf.printf "%s: %s\n" name (Time_ns.Span.to_string_hum elapsed);
  result

let () =
  Printf.printf "Compilation times:\n";
  ignore (time_compilation "boollist "
    (fun () -> BoolList.Boollist_staged_sr.make_quickcheck_generator ()));
  ignore (time_compilation "BST Repated Insert"
    (fun () -> BST.Bst_baseBespoke_Staged_SR.make_quickcheck_generator ()));
  ignore (time_compilation "BST Type"
    (fun () -> BST.Bst_baseType_Staged_SR.make_quickcheck_generator ()));
  ignore (time_compilation "BST Single Pass"
    (fun () -> BST.Bst_baseSingleBespoke_Staged_SR.make_quickcheck_generator ()));
  ignore (time_compilation "STLC Type"
    (fun () -> STLC.BaseType_Staged_SR.make_quickcheck_generator ()));
  ignore (time_compilation "STLC Bespoke"
    (fun () -> STLC.BaseBespoke_Staged_SR.make_quickcheck_generator ()));