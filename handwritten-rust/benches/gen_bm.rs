use bolero_generator::{gen, driver::{*}, ValueGenerator};
use criterion::{black_box, criterion_group, criterion_main, Criterion};


fn bench_v1(c: &mut Criterion) {
    let mut group = c.benchmark_group("Pair of Integers");
    
    group.bench_function("v1 - and_then_gen", |b| {
        let g = gen::<u32>().and_then_gen(|x: u32| (0..x).map_gen(move|y| (x,y)));
        b.iter(|| {
            let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
            g.generate(&mut driver).unwrap()
        })
    });

    group.bench_function("v2 - inline bind", |b| {
        b.iter(|| {
            let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
            let x = gen::<u32>().generate(&mut driver).unwrap();
            let y= (0..x).generate(&mut driver).unwrap();
            (x,y);
        })
    });

    group.bench_function("v3 - full direct", |b| {
        b.iter(|| {
            let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
            let x = driver.gen_u32(std::ops::Bound::Unbounded,std::ops::Bound::Unbounded).unwrap();
            let y = driver.gen_u32(std::ops::Bound::Included(&0),std::ops::Bound::Excluded(&x)).unwrap();
            (x,y);
        })
    });

    group.finish();

}

enum List{
    Nil,
    Cons(u32,Box<List>),
}


fn bench_list(c: &mut Criterion) {
    let mut group = c.benchmark_group("List");
    
    group.bench_function("v1 - and_then_gen", |b| {
        let g = gen::<u32>().and_then_gen(|x: u32| (0..x).map_gen(move|y| (x,y)));
        b.iter(|| {
            let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
            g.generate(&mut driver).unwrap()
        })
    });

    group.bench_function("v2 - inline bind", |b| {
        b.iter(|| {
            let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
            let x = gen::<u32>().generate(&mut driver).unwrap();
            let y= (0..x).generate(&mut driver).unwrap();
            (x,y);
        })
    });

    group.bench_function("v3 - full direct", |b| {
        b.iter(|| {
            let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
            let x = driver.gen_u32(std::ops::Bound::Unbounded,std::ops::Bound::Unbounded).unwrap();
            let y = driver.gen_u32(std::ops::Bound::Included(&0),std::ops::Bound::Excluded(&x)).unwrap();
            (x,y);
        })
    });

    group.finish();

}


criterion_group!(benches, bench_v1);
criterion_main!(benches);