open Core;;
open Tree;;

open Core.Quickcheck.Generator;;
open Core.Quickcheck.Let_syntax;;

let hello = [%code "hello"]

(* INLINES all definitions, plus the weighted_union, elimianting the sum. *)
let gen =
  let step gt =
      create (fun ~size ~random ->
          if size <= 1 then Leaf else
            let n = 1 + size in
            let k = Splittable_random.int random ~lo:0 ~hi:n in
            if equal k 0 then Leaf else
              let l = generate gt ~size:(size / 2) ~random in
              let r = generate gt ~size:(size / 2) ~random in
              Node (l,r)
      )
    in
    fixed_point step

let of_lazy lazy_t = create (fun ~size ~random -> generate (force lazy_t) ~size ~random)


let gen_total =
  let rec lazy_t = lazy (create (fun ~size ~random ->
    if size <= 1 then Leaf else
      let n = 1 + size in
      let k = Splittable_random.int random ~lo:0 ~hi:n in
      if equal k 0 then Leaf else
        let l = generate (force lazy_t) ~size:(size / 2) ~random in
        let r = generate (force lazy_t) ~size:(size / 2) ~random in
        Node (l,r)
     )
    )
  in
  force lazy_t