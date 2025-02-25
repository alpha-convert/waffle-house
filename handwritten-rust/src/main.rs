
use std::collections::LinkedList;
use bolero_generator::{driver::*, gen, one_of, combinator};


fn main() {
    let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
    let x = gen::<u32>().generate(&mut driver).unwrap();
    let y= (0..x).generate(&mut driver).unwrap();
    println!("{x},{y}");
    let mut driver = ByteSliceDriver::new(&[0xF,0xA,3,4,6,7,8,9], &Options::default());
    let (x,y) = gen::<u32>().and_then_gen(|x: u32| (0..x).map_gen(move|y| (x,y)) ).generate(&mut driver).unwrap();
    println!("{x},{y}");

    // let x = (1..10);
    // let y = (1..10).map_gen(|x| x + 1)
    // (1..10).generate

    let x = gen::<LinkedList<u32>>();

    let x = driver.gen_u32(std::ops::Bound::Unbounded,std::ops::Bound::Unbounded);
}
