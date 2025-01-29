open Impl;;

module Staged : Base_quickcheck.Test.S with type t = tree = struct
  (* Implement all required components here *)
  (* See the example above *)
  type t = tree [@@deriving sexp, quickcheck] (* Define the type `t` *)

  let quickcheck_generator =                              
    let rec lazy_t () =
      Base_quickcheck.Generator.create
        (fun ~size ->
            fun ~random ->
              let b = size <= 1 in
              if b
              then E
              else
                (let x = Splittable_random.int random ~lo:0 ~hi:(1 + size) in
                let b = x < 1 in
                if b
                then E
                else
                  (let x = Splittable_random.int random ~lo:0 ~hi:100 in
                    let x''1 = x in
                    let x = Splittable_random.int random ~lo:0 ~hi:100 in
                    T
                      ((Core.Quickcheck.Generator.generate ~size:(size / 2)
                          ~random (lazy_t ())), x''1, x,
                        (Core.Quickcheck.Generator.generate ~size:(size / 2)
                          ~random (lazy_t ())))))) in
    lazy_t ()
end
