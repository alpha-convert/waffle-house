module Nat = struct
  include Core.Int

  type t = Core.Int.t [@@deriving sexp, quickcheck]
  let quickcheck_generator =
    let open Base_quickcheck.Generator in
    int >>= fun i -> return (i % 128)
end


(*

let quickcheck_generator : t Code.t RandGen.t = {
    generate = (fun ~size_c ~random_c ->
      let%bind rand_int =
        Codegen.gen_let [%code
          Base_quickcheck.Generator.int_uniform_inclusive 0 [%e size_c]
          |> Core.Quickcheck.Generator.generate ~size:[%e size_c] ~random:[%e random_c]
        ]
      in
      Codegen.return [%code [%e rand_int] mod 128]
    );
  }

*)