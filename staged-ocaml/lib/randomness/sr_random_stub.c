#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

static inline int64_t mix_bits(int64_t z, int64_t n) {
  return z ^ ((uint64_t) z >> n);
}

static inline int64_t mix64(int64_t z) {
  z = mix_bits(z,33) * 0xff51afd7ed558ccdL;
  z = mix_bits(z,33) * 0xc4ceb9fe1a85ec53L;
  return mix_bits(z, 33);
}

static inline bool remainder_is_unbiased(int64_t draw, int64_t remainder, int64_t draw_max, int64_t remainder_max){
  return (draw - remainder <= draw_max - remainder_max);
}

static inline double unit_float_from_int64(int64_t n){
  return ((uint64_t) n >> 11) * pow(2,-53);
}




/*
Here, a state_t is just a "view" into an existing Splittable_random.State.t.
The seed is a pointer to the actual SR's Int64.t (techncially immutable) custom block.
Because the odd_gamma doesn't need to be mutated, we keep a copy of it.
*/
typedef struct state {
  int64_t *seed;
  int64_t odd_gamma;
} state_t;

void fill_from_value(value v, state_t* st){
    int64_t *seed = (int64_t*) Data_custom_val(Field(v,0));
    int64_t odd_gamma = Int64_val(Field(v,1));
    st->seed = seed;
    st->odd_gamma = odd_gamma;
}

int64_t next_seed_sr(state_t *s){
  int64_t next = *(s->seed) + s->odd_gamma;
  *(s->seed) = next;
  return next;
}



int64_t next_int64_sr(state_t* st){
  return mix64(next_seed_sr(st));
}

bool next_bool_sr(state_t *st){
  int64_t draw = next_int64_sr(st);
  return ((draw | 1L) == draw);
}

int64_t between_sr(state_t* st,int64_t lo,int64_t hi){
  int64_t draw = next_int64_sr(st);
  while (lo > draw || hi < draw){
    draw = next_int64_sr(st);
  }
  return draw;
}

int64_t non_negative_up_to_sr(state_t *st, int64_t max){
  int64_t draw;
  int64_t remainder;
  do {
    draw = next_int64_sr(st) & INT64_MAX;
    remainder = draw % (max + 1);
  } while (!remainder_is_unbiased(draw,remainder,INT64_MAX,max));
  return remainder;
}

int64_t next_int_sr(state_t *st,int64_t lo, int64_t hi){
  int64_t diff = hi - lo;
  int64_t result;
  if(diff == INT64_MAX){
    result = ((next_int64_sr(st) & INT64_MAX) + lo);
  } else if (diff >= 0){
    result = non_negative_up_to_sr(st,diff) + lo;
  } else {
    result = between_sr(st,lo,hi);
  }

  return result;
}

double unit_float_sr(state_t *st){
  return unit_float_from_int64(next_int64_sr(st));
}


double next_float_sr(state_t *st, double lo, double hi){
  while(!(isfinite(hi - lo))){
    double mid = (hi + lo) / 2.0;
    if(next_bool_sr(st)){
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return (lo + unit_float_sr(st) * (hi - lo));

}

CAMLprim value bool_c_sr(value sr_state_val) {
  CAMLparam1(sr_state_val);
  state_t* st = (state_t*) alloca(sizeof(state_t));
  fill_from_value(sr_state_val,st);
  CAMLreturn(Val_bool(next_bool_sr(st)));
}



CAMLprim double float_c_sr_unchecked_unboxed(value sr_state_val, double lo, double hi){
  CAMLparam1(sr_state_val);
  state_t* st = (state_t*) alloca(sizeof(state_t));
  fill_from_value(sr_state_val,st);
  // double lo = Double_val(lo_val);
  // double hi = Double_val(hi_val);
  double result = next_float_sr(st,lo,hi);
  CAMLreturn(result);
}

CAMLprim value float_c_sr_unchecked(value sr_state_val, value lo_val, value hi_val){
  CAMLparam3(sr_state_val,lo_val,hi_val);
  CAMLreturn(caml_copy_double(float_c_sr_unchecked_unboxed(sr_state_val,Double_val(lo_val),Double_val(hi_val))));
}

CAMLprim value int_c_sr_unchecked(value sr_state_val, value lo_val, value hi_val) {
  CAMLparam3(sr_state_val,lo_val,hi_val);
  state_t* st = (state_t*) alloca(sizeof(state_t));
  fill_from_value(sr_state_val,st);

  int64_t lo = (int64_t) Long_val(lo_val);
  int64_t hi = (int64_t) Long_val(hi_val);

  int64_t result = next_int_sr(st,lo,hi);
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
  uint64_t n = 0;
  
  while (t > 0) {
      t >>= 1;
      n++;
  }
  
  return n;
}

static int64_t next_int_log_uniform(state_t *st, int64_t lo, int64_t hi) {
  uint64_t min_bits = bits_to_represent(lo);
  uint64_t max_bits = bits_to_represent(hi);
  int64_t bits = next_int_sr(st,min_bits,max_bits);
  lo = max(lo,min_represented_by_n_bits(bits));
  hi = min(hi,max_represented_by_n_bits(bits));
  return next_int_sr(st,lo,hi);
}

CAMLprim value int_c_sr_log_uniform(value sr_state_val, value lo_val, value hi_val) {
  CAMLparam3(sr_state_val,lo_val,hi_val);
  state_t* st = (state_t*) alloca(sizeof(state_t));
  fill_from_value(sr_state_val,st);

  int64_t lo = (int64_t) Long_val(lo_val);
  int64_t hi = (int64_t) Long_val(hi_val);

  int64_t result = next_int_log_uniform(st,lo,hi);
  CAMLreturn(Val_int(result));
}

// CAMLprim value print(value state_val) {
//   CAMLparam1(state_val);
//   state_t st = State_val(state_val);
//   printf("C-Seed: %ld\n", st.seed);
//   CAMLreturn(Val_unit);
// }

static inline int64_t to_int64_preserve_order(double t){
  if(t == 0.0) {
    return 0L;
  } else if(t > 0.0){
    return ((int64_t) t);
  } else {
    return (- ((int64_t) (-t)));
  }
}

static inline double of_int64_preserve_order(double x){
  if(x >= 0L){
    return ((double) x);
  } else {
    return -((double) (-x));
  }
}

CAMLprim double one_ulp_up_c_sr_unboxed(double x){
  CAMLparam0();
  double res;
  if(isnan(x)){
    res = NAN;
  } else {
    res = of_int64_preserve_order(to_int64_preserve_order(x) + 1L);
  }
  return res;
}

CAMLprim value one_ulp_up_c_sr(value x_val){
  CAMLparam1(x_val);
  CAMLreturn(caml_copy_double(one_ulp_up_c_sr_unboxed(Double_val(x_val))));
}

CAMLprim double one_ulp_down_c_sr_unboxed(double x){
  CAMLparam0();
  double res;
  if(isnan(x)){
    res = NAN;
  } else {
    res = of_int64_preserve_order(to_int64_preserve_order(x) - 1L);
  }
  return res;
}

CAMLprim value one_ulp_down_c_sr(value x_val){
  CAMLparam1(x_val);
  CAMLreturn(caml_copy_double(one_ulp_down_c_sr_unboxed(Double_val(x_val))));
}