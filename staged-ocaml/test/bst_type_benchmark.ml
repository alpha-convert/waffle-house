let () = Gc.full_major ()
let () =
  Benchmark.bm_nondet ~bench_name:"bst_type"
    ~sizes:[10;100;1000;10000]
    ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.))
    ~named_gens:[
      "baseType", BST.Bst_baseType.quickcheck_generator;
      "baseType_Staged_SR", BST.Bst_baseType_Staged_SR.quickcheck_generator;
      "baseType_Staged_CSR", BST.Bst_baseType_Staged_CSR.quickcheck_generator;
    ]