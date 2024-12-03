open Core;;
open Staged_generator;;
open Staged_generator.Let_syntax;;

let gc : Tree.tree Core.Quickcheck.Generator.t Code.t =
  recursive (fun (rec_call : Tree.tree recgen)->
    let%bind n = size in
    gen_if [%code [%e n] <= 1] (return [%code Tree.Leaf]) (
      choose
      ([%code 1],(return [%code Tree.Leaf]))
      (n,
        let%bind l = with_size (recurse rec_call) ~size_c:[%code [%e n]/2] in
        let%bind r = with_size (recurse rec_call) ~size_c:[%code [%e n]/2] in
        return [%code Tree.Node([%e l],[%e r])]
       )
    )
  )

(*This is what you get if you print the above.*)
 let splat =                            
  let rec lazy_t () =
    Base_quickcheck.Generator.create
      (fun ~size ->
         fun ~random ->
           let b = size <= 1 in
           if b
           then Tree.Leaf
           else
             (let x = 1 + size in
              let x = min 1 size in
              let x''1 = x in
              let x = max 1 size in
              let x = Splittable_random.int random ~lo:x''1 ~hi:x in
              let b = 1 < size in
              if b
              then
                let b = x < 1 in
                (if b
                 then Tree.Leaf
                 else
                   Tree.Node
                     ((Core.Quickcheck.Generator.generate ~size:(size / 2)
                         ~random (lazy_t ())),
                       (Core.Quickcheck.Generator.generate ~size:(size / 2)
                          ~random (lazy_t ()))))
              else
                (let b = x < size in
                 if b
                 then
                   Tree.Node
                     ((Core.Quickcheck.Generator.generate ~size:(size / 2)
                         ~random (lazy_t ())),
                       (Core.Quickcheck.Generator.generate ~size:(size / 2)
                          ~random (lazy_t ())))
                 else Tree.Leaf))) in
  lazy_t ()