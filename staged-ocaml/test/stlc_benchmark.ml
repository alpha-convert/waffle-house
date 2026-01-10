let () = Gc.full_major ()
let () =
  Benchmark.bm_nondet ~bench_name:"stlc"
    ~sizes:[10;100;1000;10000]
    ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.))
    ~named_gens:[
      "baseBespoke", STLC.BaseBespoke.quickcheck_generator;
      "baseBespoke_Staged_SR", STLC.BaseBespoke_Staged_SR.quickcheck_generator;
      "baseBespoke_Staged_CSR", STLC.BaseBespoke_Staged_CSR.quickcheck_generator;
    ]