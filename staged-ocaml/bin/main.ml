let random = Core.Splittable_random.State.of_int (-11060854624)

let x1 = Obj.magic 1.
let x2 = Obj.magic 2.
let x3 = Obj.magic 1.
let a1 = Core.(+.) 0. x1
let a2 = Core.(+.) a1 x2
let a3 = Core.(+.) a2 x3

let arr = Array.of_list [a1;a2;a3]
let choice = Core.Splittable_random.float random ~lo:0. ~hi:a3
let () = Core.Array.iter arr ~f:(fun f -> print_endline ("Elt: " ^ Float.to_string f))
(* let () = print_endline ("Arr: " ^ (Array.to_string arr)) *)
let () = print_endline ("Choice" ^ Float.to_string choice)
let Some v = Core.Array.binary_search arr ~compare:Float.compare `First_greater_than_or_equal_to choice
let () = print_endline ("found: " ^ Int.to_string v)
