let () =
  Benchmark.bm_nondet ~bench_name:"bst"
    ~sizes:[10;100;1000;10000]
    ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.))
    ~named_gens:[
      "baseBespoke", Bst_baseBespoke.quickcheck_generator;
      "baseBespoke_Staged_SR", Bst_baseBespoke_Staged_SR.quickcheck_generator;
      "baseBespoke_Staged_CSR", Bst_baseBespoke_Staged_CSR.quickcheck_generator;
      "baseSingleBespoke", Bst_baseSingleBespoke.quickcheck_generator;
      "baseSingleBespoke_Staged_SR", Bst_baseSingleBespoke_Staged_SR.quickcheck_generator;
      "baseSingleBespoke_Staged_CSR", Bst_baseSingleBespoke_Staged_CSR.quickcheck_generator;
      "baseType", Bst_baseType.quickcheck_generator;
      "baseType_Staged_SR", Bst_baseType_Staged_SR.quickcheck_generator;
      "baseType_Staged_CSR", Bst_baseType_Staged_CSR.quickcheck_generator;
    ]