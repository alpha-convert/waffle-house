#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <math.h>


static bool remainder_is_unbiased(int64_t draw, int64_t remainder, int64_t draw_max, int64_t remainder_max){
  return (draw - remainder <= draw_max - remainder_max);
}

static double unit_float_from_int64(int64_t n){
  return ((uint64_t) n >> 11) * pow(2,-53);
}

static __uint128_t lehmer_state;

void populate_from(value sr_val) {
  lehmer_state = ((__uint128_t) Int64_val(Field(sr_val,0))) << 64;
}

static inline uint64_t next_int64() {
    lehmer_state *= 0xda942042e4dd58b5;
    return lehmer_state >> 64;
  }


static bool next_bool(){
  int64_t draw = next_int64();
  return ((draw | 1L) == draw);
}

static int64_t between(int64_t lo,int64_t hi){
  int64_t draw = next_int64();
  while (lo > draw || hi < draw){
    draw = next_int64();
  }
  return draw;
}

static int64_t non_negative_up_to(int64_t max){
  int64_t draw;
  int64_t remainder;
  do {
    draw = next_int64() & INT64_MAX;
    remainder = draw % (max + 1);
  } while (!remainder_is_unbiased(draw,remainder,INT64_MAX,max));
  return remainder;
}

static int64_t next_int(int64_t lo, int64_t hi){
  int64_t diff = hi - lo;
  int64_t result;
  if(diff == INT64_MAX){
    result = ((next_int64() & INT64_MAX) + lo);
  } else if (diff >= 0){
    result = non_negative_up_to(diff) + lo;
  } else {
    result = between(lo,hi);
  }

  return result;
}



static double unit_float(){
  return unit_float_from_int64(next_int64());
}


static double next_float(double lo, double hi){
  while(!(isfinite(hi - lo))){
    double mid = (hi + lo) / 2.0;
    if(next_bool()){
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return (lo + unit_float() * (hi - lo));

}

CAMLprim value bool_lehmer(value state_val) {
  CAMLparam1(state_val);
  populate_from(state_val);
  CAMLreturn(Val_bool(next_bool()));
}

double float_lehmer_unchecked_unboxed(value state_val, double lo, double hi){
  populate_from(state_val);
  return next_float(lo,hi);
}

CAMLprim value float_lehmer_unchecked(value state_val, value lo_val, value hi_val){
  CAMLparam3(state_val,lo_val,hi_val);
  value v = caml_copy_double(float_lehmer_unchecked_unboxed(state_val,Double_val(lo_val),Double_val(hi_val)));
  CAMLreturn(v);
}

CAMLprim value int_lehmer_unchecked(value state_val, value lo_val, value hi_val) {
  CAMLparam3(state_val,lo_val,hi_val);
  populate_from(state_val);

  int64_t lo = (int64_t) Long_val(lo_val);
  int64_t hi = (int64_t) Long_val(hi_val);

  int64_t result = next_int(lo,hi);
  CAMLreturn(Val_int(result));
}


static inline int64_t min_represented_by_n_bits(int64_t n) {
  if (n == 0) {
      return 0;
  } else {
      return 1LL << (n - 1);
  }
}

static inline int64_t max_represented_by_n_bits(int64_t bits) {
  return (1LL << bits) - 1;
}


static inline int64_t max(int64_t a, int64_t b) {
  return (a > b) ? a : b;
}

static inline int64_t min(int64_t a, int64_t b) {
  return (a < b) ? a : b;
}

static uint64_t bits_to_represent(int64_t t) {
  if (t == 0) return 0;
  return 64 - __builtin_clzll((uint64_t)t);
}



static int64_t next_int_log_uniform(int64_t lo, int64_t hi) {
  uint64_t min_bits = bits_to_represent(lo);
  uint64_t max_bits = bits_to_represent(hi);
  int64_t bits = next_int(min_bits,max_bits);
  lo = max(lo,min_represented_by_n_bits(bits));
  hi = min(hi,max_represented_by_n_bits(bits));
  return next_int(lo,hi);
}

CAMLprim value int_lehmer_log_uniform(value state_val, value lo_val, value hi_val) {
  CAMLparam3(state_val,lo_val,hi_val);
  populate_from(state_val);

  int64_t lo = (int64_t) Long_val(lo_val);
  int64_t hi = (int64_t) Long_val(hi_val);

  int64_t result = next_int_log_uniform(lo,hi);
  CAMLreturn(Val_int(result));
}

CAMLprim value print_lehmer(value state_val) {
  CAMLparam1(state_val);
  populate_from(state_val);
  printf("C-Seed: %llx\n", (unsigned long long) lehmer_state);
  CAMLreturn(Val_unit);
}


CAMLprim value repopulate_lehmer(value state_val, value sr_state_val) {
  CAMLparam2(state_val, sr_state_val);

//   Int64_val(Field(sr_state_val,0)) = s.seed;
//   Int64_val(Field(sr_state_val,1)) = s.odd_gamma;
  
  CAMLreturn(Val_unit);
}