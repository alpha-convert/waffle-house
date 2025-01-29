open Impl

let blacken_correct (t : tree) : tree =
  match t with E -> E | T (_, a, k, v, b) -> T (B, a, k, v, b)

let balance_correct (col : color) (tl : tree) (k : Nat.t) (v : Nat.t)
    (tr : tree) : tree =
  match (col, tl, k, v, tr) with
  | B, T (R, T (R, a, x, vx, b), y, vy, c), z, vz, d ->
      T (R, T (B, a, x, vx, b), y, vy, T (B, c, z, vz, d))
  | B, T (R, a, x, vx, T (R, b, y, vy, c)), z, vz, d ->
      T (R, T (B, a, x, vx, b), y, vy, T (B, c, z, vz, d))
  | B, a, x, vx, T (R, T (R, b, y, vy, c), z, vz, d) ->
      T (R, T (B, a, x, vx, b), y, vy, T (B, c, z, vz, d))
  | B, a, x, vx, T (R, b, y, vy, T (R, c, z, vz, d)) ->
      T (R, T (B, a, x, vx, b), y, vy, T (B, c, z, vz, d))
  | rb, a, x, vx, b -> T (rb, a, x, vx, b)

let insert_correct s (k, vk) : tree =
  let rec ins x vx t =
    match t with
    | E -> T (R, E, x, vx, E)
    | T (rb, a, y, vy, b) ->
        if x < y then balance_correct rb (ins x vx a) y vy b
        else if x > y then balance_correct rb a y vy (ins x vx b)
        else T (rb, a, y, vx, b)
  in
  blacken_correct (ins k vk s)

module BaseBespoke : Base_quickcheck.Test.S with type t = rbt = struct
  type t = rbt [@@deriving sexp, quickcheck]

  let quickcheck_generator =
    let open Base_quickcheck.Generator in
    list (both Nat.quickcheck_generator Nat.quickcheck_generator)
    >>= fun l -> Base.List.fold l ~init:E ~f:insert_correct |> return
end
