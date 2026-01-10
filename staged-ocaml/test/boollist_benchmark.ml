let () =
  Benchmark.bm_nondet ~bench_name:"boollist"
    ~sizes:[10;100;1000;10000]
    ~quota:(Core_bench.Bench.Quota.Span (Core.sec 5.))
    ~named_gens:[
      "base", BoolList.Boollist.quickcheck_generator;
      "staged_sr", BoolList.Boollist_staged_sr.quickcheck_generator;
      "staged_csr", BoolList.Boollist_staged_csr.quickcheck_generator;
    ]