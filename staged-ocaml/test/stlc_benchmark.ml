let () =
  Benchmark.bm_nondet ~bench_name:"stlc"
    ~sizes:[10;100;1000;10000]
    ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.))
    ~named_gens:[
      "baseBespoke", Stlc_baseBespoke.quickcheck_generator;
      "baseBespoke_Staged_SR", Stlc_baseBespoke_Staged_SR.quickcheck_generator;
      "baseBespoke_Staged_CSR", Stlc_baseBespoke_Staged_CSR.quickcheck_generator;
      "baseType", Stlc_baseType.quickcheck_generator;
      "baseType_Staged_SR", Stlc_baseType_Staged_SR.quickcheck_generator;
      "baseType_Staged_CSR", Stlc_baseType_Staged_CSR.quickcheck_generator;
    ]