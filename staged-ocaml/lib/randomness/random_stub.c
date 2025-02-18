#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <math.h>


typedef struct state {
  int64_t seed;
  int64_t odd_gamma;
} state_t;

static struct custom_operations state_ops = {
  "jwc.c_splitmix",
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

#define State_val(v) (*((state_t *) Data_custom_val(v)))

/*
NOTE: We could get around this single allocation (which will happen at the beginning of every generator call)
by just punning the original state type of splittable_random, and just doing all of the int64 math in place.
Doing it this way is *technically* illegal, since if I have a record like { mutable x : int64 }, it is (apparently) *not safe*
to mutate the underlying int64 without allocating a fresh box. (!!).
*/
CAMLprim value create_state(value seed, value gamma) {
  CAMLparam2(seed, gamma);
  CAMLlocal1(result);
  
  state_t s;
  s.seed = Int64_val(seed);
  s.odd_gamma = Int64_val(gamma);
  
  result = caml_alloc_custom(&state_ops, sizeof(state_t), 0, 1);
  State_val(result) = s;
  
  CAMLreturn(result);
}

int64_t next_seed(state_t *s){
  int64_t next = s->seed + s->odd_gamma;
  s->seed = next;
  return next;
}

// This bug took me forever to figure out. A "logical shift right" requires
// casting to uint64_t first.
int64_t mix_bits(int64_t z, int64_t n) {
  return z ^ ((uint64_t) z >> n);
}

int64_t mix64(int64_t z) {
  z = mix_bits(z,33) * 0xff51afd7ed558ccdL;
  z = mix_bits(z,33) * 0xc4ceb9fe1a85ec53L;
  return mix_bits(z, 33);
}

int64_t next_int64(state_t* st){
  return mix64(next_seed(st));
}

bool next_bool(state_t *st){
  int64_t draw = next_int64(st);
  return ((draw | 1L) == draw);
}

CAMLprim value bool_c(value state_val) {
  CAMLparam1(state_val);
  state_t st = State_val(state_val);
  CAMLreturn(Val_bool(next_bool(&st)));
}


bool remainder_is_unbiased(int64_t draw, int64_t remainder, int64_t draw_max, int64_t remainder_max){
  return (draw - remainder <= draw_max - remainder_max);
}

int64_t between(state_t* st,int64_t lo,int64_t hi){
  int64_t draw = next_int64(st);
  while (lo > draw || hi < draw){
    draw = next_int64(st);
  }
  return draw;
}

int64_t non_negative_up_to(state_t *st, int64_t max){
  int64_t draw;
  int64_t remainder;
  do {
    draw = next_int64(st) & INT64_MAX;
    remainder = draw % (max + 1);
  } while (!remainder_is_unbiased(draw,remainder,INT64_MAX,max));
  return remainder;
}

CAMLprim value int_c_unchecked(value state_val, value lo_val, value hi_val) {
  CAMLparam3(state_val,lo_val,hi_val);
  state_t st = State_val(state_val);

  int64_t lo = (int64_t) Int_val(lo_val);
  int64_t hi = (int64_t) Int_val(hi_val);

  int64_t diff = hi - lo;
  int64_t result;
  if(diff == INT64_MAX){
    result = ((next_int64(&st) & INT64_MAX) + lo);
  } else if (diff >= 0){
    result = non_negative_up_to(&st,diff) + lo;
  } else {
    result = between(&st,lo,hi);
  }
  CAMLreturn(Val_int(result));
}

double unit_float_from_int64(int64_t n){
  return ((uint64_t) n >> 11) * pow(2,-53);
}
// let unit_float_from_int64 int64 = Int64.to_float (int64 lsr 11) *. double_ulp

double unit_float(state_t *st){
  return unit_float_from_int64(next_int64(st));
}


double finite_float(state_t *st, double lo, double hi){
  while(!(isfinite(hi - lo))){
    double mid = (hi + lo) / 2.0;
    if(next_bool(st)){
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return (lo + unit_float(st) * (hi - lo));

}

CAMLprim value float_c_unchecked(value state_val, value lo_val, value hi_val){
  CAMLparam3(state_val,lo_val,hi_val);
  state_t st = State_val(state_val);
  double lo = Double_val(lo_val);
  double hi = Double_val(hi_val);
  double result = finite_float(&st,lo,hi);
  CAMLreturn(caml_copy_double(result));
}

CAMLprim value print(value state_val) {
  CAMLparam1(state_val);
  state_t *st = Data_custom_val(state_val);
  printf("C-Seed: %ld\n", st->seed);
  CAMLreturn(Val_unit);
}