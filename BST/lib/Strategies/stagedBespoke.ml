open Impl
open Base

module StagedBespoke : Base_quickcheck.Test.S with type t = tree = struct
  type t = tree [@@deriving sexp, quickcheck]

  let quickcheck_generator =
    let open Base_quickcheck.Generator in
    let rec gen lo hi size random =
      if size <= 0 || lo >= hi then E
      else
        let flip = Splittable_random.int random ~lo:0 ~hi:(1 + size) in
        if flip < 1 then E
        else
          let k = Splittable_random.int random ~lo ~hi:(hi - 1) in
          let v = Splittable_random.int random ~lo:0 ~hi:size in
          let l = gen lo k (size / 2) random in
          let r = gen k hi (size / 2) random in
          T (l, k, v, r)
    in
    create (fun ~size ~random ->
      gen 0 size size random)
end
