open Impl

module BaseTypeStaged : Base_quickcheck.Test.S with type t = rbt = struct
  type t = rbt [@@deriving sexp, quickcheck]

  let quickcheck_generator =                              
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
                  (let x = (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
                   let x''1 = x in
                   let x = (Splittable_random.int random ~lo:0 ~hi:100) mod 128 in
                   let x''2 = x in
                   let x = Splittable_random.bool random in
                   let b = x in
                   if b
                   then
                     Impl.T
                       (Impl.R,
                         (Core.Quickcheck.Generator.generate ~size:(size / 2)
                            ~random (lazy_t ())), x''1, x''2,
                         (Core.Quickcheck.Generator.generate ~size:(size / 2)
                            ~random (lazy_t ())))
                   else
                     Impl.T
                       (Impl.B,
                         (Core.Quickcheck.Generator.generate ~size:(size / 2)
                            ~random (lazy_t ())), x''1, x''2,
                         (Core.Quickcheck.Generator.generate ~size:(size / 2)
                            ~random (lazy_t ())))))) in
    lazy_t ()
end
