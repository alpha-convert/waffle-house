open Core;;
open Staged_generator;;
open Staged_generator.Let_syntax;;

let gc =
  recursive (fun gt ->
    let%bind n = size in
    gen_if [%code [%e n] <= 1] (return [%code Tree.E]) (
      choose
      ([%code 1], (return [%code Tree.E]))
      (n,
        let%bind k = random_int ~lo:[%code 0] ~hi:[%code 100] in
        let%bind v = random_int ~lo:[%code 0] ~hi:[%code 100] in
        let%bind l = with_size (recurse gt) ~size_c:[%code [%e n]/2] in
        let%bind r = with_size (recurse gt) ~size_c:[%code [%e n]/2] in
        return [%code Tree.T ([%e l], [%e k], [%e v], [%e r])]
       )
    )
  )

let gc_rbt =
  recursive (fun gt ->
      let%bind n = size in
      gen_if [%code [%e n] <= 1] (return [%code Impl.E]) (
        choose
        ([%code 1], (return [%code Impl.E]))
        (n,
          let%bind k = random_int ~lo:[%code 0] ~hi:[%code 100] in
          let%bind v = random_int ~lo:[%code 0] ~hi:[%code 100] in    
          let%bind c = random_color in      
          let%bind l = with_size (recurse gt) ~size_c:[%code [%e n]/2] in
          let%bind r = with_size (recurse gt) ~size_c:[%code [%e n]/2] in
          return [%code Impl.T ([%e c], [%e l], [%e k], [%e v], [%e r])]
         )
      )
    )

let splat =                            
      let rec lazy_t () =
        Base_quickcheck.Generator.create
          (fun ~size ->
             fun ~random ->
               let b = size <= 1 in
               if b
               then Tree.Leaf
               else
                 (let x = Splittable_random.int random ~lo:0 ~hi:(1 + size) in
                  let b = x < 1 in
                  if b
                  then Tree.Leaf
                  else
                    Tree.Node
                      ((Core.Quickcheck.Generator.generate ~size:(size / 2)
                          ~random (lazy_t ())),
                        (Core.Quickcheck.Generator.generate ~size:(size / 2)
                           ~random (lazy_t ()))))) in
      lazy_t ()

let splat' =                              
  let rec lazy_t () =
    Base_quickcheck.Generator.create
      (fun ~size ->
          fun ~random ->
            let b = size <= 1 in
            if b
            then Tree.E
            else
              (let x = Splittable_random.int random ~lo:0 ~hi:(1 + size) in
              let b = x < 1 in
              if b
              then Tree.E
              else
                (let x = Splittable_random.int random ~lo:0 ~hi:100 in
                  let x''1 = x in
                  let x = Splittable_random.int random ~lo:0 ~hi:100 in
                  Tree.T
                    ((Core.Quickcheck.Generator.generate ~size:(size / 2)
                        ~random (lazy_t ())), x''1, x,
                      (Core.Quickcheck.Generator.generate ~size:(size / 2)
                        ~random (lazy_t ())))))) in
  lazy_t ()

let splat_rbt =                               
  let rec lazy_t () =
    Base_quickcheck.Generator.create
      (fun ~size ->
          fun ~random ->
            let b = size <= 1 in
            if b
            then Impl.E
            else
              (let x = Splittable_random.int random ~lo:0 ~hi:(1 + size) in
              let b = x < 1 in
              if b
              then Impl.E
              else
                (let x = Splittable_random.int random ~lo:0 ~hi:2 in
                  let b = x = 0 in
                  if b
                  then
                    let x =
                      (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
                    let x''1 = x in
                    let x =
                      (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
                    Impl.T
                      (Impl.R,
                        (Core.Quickcheck.Generator.generate ~size:(size / 2)
                          ~random (lazy_t ())), x''1, x,
                        (Core.Quickcheck.Generator.generate ~size:(size / 2)
                          ~random (lazy_t ())))
                  else
                    (let x =
                      (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
                    let x''1 = x in
                    let x =
                      (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
                    Impl.T
                      (Impl.B,
                        (Core.Quickcheck.Generator.generate ~size:(size / 2)
                            ~random (lazy_t ())), x''1, x,
                        (Core.Quickcheck.Generator.generate ~size:(size / 2)
                            ~random (lazy_t ()))))))) in
  lazy_t ()

(*
let splat' =                              
  let rec lazy_t () =
    Base_quickcheck.Generator.create
      (fun ~size ->
          fun ~random ->
            let b = size <= 1 in
            if b
            then Tree.E
            else
              (let x = Splittable_random.int random ~lo:0 ~hi:(1 + size) in
              let b = x < 1 in
              if b
              then Tree.E
              else
                (let x =
                    Nat.quickcheck_generator |>
                      (Core.Quickcheck.Generator.generate ~size:10 ~random) in
                  let x''1 = x in
                  let x =
                    Nat.quickcheck_generator |>
                      (Core.Quickcheck.Generator.generate ~size:10 ~random) in
                  Tree.T
                    ((Core.Quickcheck.Generator.generate ~size:(size / 2)
                        ~random (lazy_t ())), x''1, x,
                      (Core.Quickcheck.Generator.generate ~size:(size / 2)
                        ~random (lazy_t ())))))) in
  lazy_t ()
*)

(* Print the transformed code *)
let () =
  let parsetree_structure = Ppx_stage.to_parsetree_structure gc_rbt in
  Format.printf "%a\n" Pprintast.structure parsetree_structure
