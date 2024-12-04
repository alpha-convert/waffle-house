open Core;;
open Staged_generator;;
open Staged_generator.Let_syntax;;

let gc =
  recursive (fun gt ->
    let%bind n = size in
    gen_if [%code [%e n] <= 1] (return [%code Tree.Leaf]) (
      choose
      ([%code 1],(return [%code Tree.Leaf]))
      (n,
        let%bind l = with_size (recurse gt) ~size_c:[%code [%e n]/2] in
        let%bind r = with_size (recurse gt) ~size_c:[%code [%e n]/2] in
        return [%code Tree.Node([%e l],[%e r])]
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