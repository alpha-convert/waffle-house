open Type

let rec format_tree ppf tree =
  let open Format in
  match tree with
  | E -> fprintf ppf "E"
  | T (left, key, value, right) ->
      fprintf ppf "T (%a, %s, %s, %a)" format_tree left (Nat.to_string key) (Nat.to_string value) format_tree
        right

let rec string_of_tree = function
  | E -> "Empty"
  | T (l, k, v, r) ->
      "Tree (" ^ string_of_tree l ^ "," ^ Nat.to_string k ^ ","
      ^ Nat.to_string v ^ "," ^ string_of_tree r ^ ")"
