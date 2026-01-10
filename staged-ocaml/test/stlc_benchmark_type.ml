let () = Gc.full_major ()
let () =
  Benchmark.bm_nondet ~bench_name:"stlc"
    ~sizes:[10;100;1000;10000]
    ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.))
    ~named_gens:[
      "baseType", STLC.BaseType.quickcheck_generator;
      "baseType_Staged_SR", STLC.BaseType_Staged_SR.quickcheck_generator;
      "baseType_Staged_CSR", STLC.BaseType_Staged_CSR.quickcheck_generator;
    ]