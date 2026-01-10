let () = Gc.full_major ()
let () =
  Benchmark.bm_nondet ~bench_name:"bst_single"
    ~sizes:[10;100;1000;10000]
    ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.))
    ~named_gens:[
      "baseSingleBespoke", BST.Bst_baseSingleBespoke.quickcheck_generator;
      "baseSingleBespoke_Staged_SR", BST.Bst_baseSingleBespoke_Staged_SR.quickcheck_generator;
      "baseSingleBespoke_Staged_CSR", BST.Bst_baseSingleBespoke_Staged_CSR.quickcheck_generator;
    ]