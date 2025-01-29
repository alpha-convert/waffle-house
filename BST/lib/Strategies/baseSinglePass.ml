open Impl
open Base

module BaseSinglePass : Base_quickcheck.Test.S with type t = tree = struct
  type t = tree [@@deriving sexp, quickcheck]

  let quickcheck_generator =
    let open Base_quickcheck.Generator in
    let open Let_syntax in
    let rec gen lo hi =
      let%bind n = size in
      if n <= 0 || lo >= hi then return E
      else
        weighted_union [
          (1.0, return E);
          (Float.of_int n, 
            let%bind k = int_uniform_inclusive lo (hi - 1) in
            let%bind v = int_uniform_inclusive 0 n in
            let%bind l = with_size ~size:(n / 2) (gen lo k) in
            let%bind r = with_size ~size:(n / 2) (gen k hi) in
            return (T (l, k, v, r))
          )
        ]
      in
      let%bind n = size in
      gen 0 n
  end