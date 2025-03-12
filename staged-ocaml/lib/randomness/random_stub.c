#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

int64_t mix_bits(int64_t z, int64_t n) {
  return z ^ ((uint64_t) z >> n);
}

int64_t mix64(int64_t z) {
  z = mix_bits(z,33) * 0xff51afd7ed558ccdL;
  z = mix_bits(z,33) * 0xc4ceb9fe1a85ec53L;
  return mix_bits(z, 33);
}

bool remainder_is_unbiased(int64_t draw, int64_t remainder, int64_t draw_max, int64_t remainder_max){
  return (draw - remainder <= draw_max - remainder_max);
}

double unit_float_from_int64(int64_t n){
  return ((uint64_t) n >> 11) * pow(2,-53);
}


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
#define State_ptr(v) ((state_t *) Data_custom_val(v))

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

int64_t next_int64(state_t* st){
  return mix64(next_seed(st));
}

bool next_bool(state_t *st){
  int64_t draw = next_int64(st);
  return ((draw | 1L) == draw);
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

int64_t next_int(state_t *st,int64_t lo, int64_t hi){
  int64_t diff = hi - lo;
  int64_t result;
  if(diff == INT64_MAX){
    result = ((next_int64(st) & INT64_MAX) + lo);
  } else if (diff >= 0){
    result = non_negative_up_to(st,diff) + lo;
  } else {
    result = between(st,lo,hi);
  }

  return result;
}



double unit_float(state_t *st){
  return unit_float_from_int64(next_int64(st));
}


double next_float(state_t *st, double lo, double hi){
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

CAMLprim value bool_c(value state_val) {
  CAMLparam1(state_val);
  state_t *st = State_ptr(state_val);
  CAMLreturn(Val_bool(next_bool(st)));
}

double float_c_unchecked_unboxed(value state_val, double lo, double hi){
  // CAMLparam1(state_val);
  state_t *st = State_ptr(state_val);
  double result = next_float(st,lo,hi);
  return result;
}

CAMLprim value float_c_unchecked(value state_val, value lo_val, value hi_val){
  CAMLparam3(state_val,lo_val,hi_val);
  value v = caml_copy_double(float_c_unchecked_unboxed(state_val,Double_val(lo_val),Double_val(hi_val)));
  CAMLreturn(v);
}

CAMLprim value int_c_unchecked(value state_val, value lo_val, value hi_val) {
  CAMLparam3(state_val,lo_val,hi_val);
  state_t *st = State_ptr(state_val);

  int64_t lo = (int64_t) Long_val(lo_val);
  int64_t hi = (int64_t) Long_val(hi_val);

  int64_t result = next_int(st,lo,hi);
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



int64_t next_int_log_uniform(state_t *st, int64_t lo, int64_t hi) {
  uint64_t min_bits = bits_to_represent(lo);
  uint64_t max_bits = bits_to_represent(hi);
  int64_t bits = next_int(st,min_bits,max_bits);
  lo = max(lo,min_represented_by_n_bits(bits));
  hi = min(hi,max_represented_by_n_bits(bits));
  return next_int(st,lo,hi);
}

CAMLprim value int_c_log_uniform(value state_val, value lo_val, value hi_val) {
  CAMLparam3(state_val,lo_val,hi_val);
  state_t *st = State_ptr(state_val);

  int64_t lo = (int64_t) Long_val(lo_val);
  int64_t hi = (int64_t) Long_val(hi_val);

  int64_t result = next_int_log_uniform(st,lo,hi);
  CAMLreturn(Val_int(result));
}

CAMLprim value print(value state_val) {
  CAMLparam1(state_val);
  state_t st = State_val(state_val);
  printf("C-Seed: %ld\n", st.seed);
  CAMLreturn(Val_unit);
}

static inline double bitcast_int64_to_double(int64_t value) {
  return *(double*)&value;
  // double result;
  // memcpy(&result, &value, sizeof(double));
  // return result;
}

static inline int64_t bitcast_double_to_int64(double value) {
  return *(int64_t*)&value;
  // int64_t result;
  // memcpy(&result, &value, sizeof(int64_t));
  // return result;
}

static inline int64_t to_int64_preserve_order(double t){
  if(t == 0.0) {
    return 0L;
  } else if(t > 0.0){
    return (bitcast_double_to_int64(t));
  } else {
    return (- (bitcast_double_to_int64(-t)));
  }
}

static inline double of_int64_preserve_order(int64_t x){
  if(x >= 0L){
    return (bitcast_int64_to_double(x));
  } else {
    return -(bitcast_int64_to_double(-x));
  }
}

double one_ulp_up_c_unboxed(double x){
  double res;
  if(isnan(x)){
    res = NAN;
  } else {
    res = of_int64_preserve_order(to_int64_preserve_order(x) + 1L);
  }
  return res;
}

CAMLprim value one_ulp_up_c(value x_val){
  CAMLparam1(x_val);
  CAMLreturn(caml_copy_double(one_ulp_up_c_unboxed(Double_val(x_val))));
}

double one_ulp_down_c_unboxed(double x){
  double res;
  if(isnan(x)){
    res = NAN;
  } else {
    res = of_int64_preserve_order(to_int64_preserve_order(x) - 1L);
  }
  return res;
}

CAMLprim value one_ulp_down_c(value x_val){
  CAMLparam1(x_val);
  CAMLreturn(caml_copy_double(one_ulp_down_c_unboxed(Double_val(x_val))));
}

// void fill_from_value(value v){
//     int64_t *seed = (int64_t*) Data_custom_val(Field(v,0));
//     int64_t odd_gamma = Int64_val(Field(v,1));
//     global_state.seed = seed;
//     global_state.odd_gamma = odd_gamma;
// }

CAMLprim value repopulate(value state_val, value sr_state_val) {
  CAMLparam2(state_val, sr_state_val);

  state_t s = State_val(state_val);

  Int64_val(Field(sr_state_val,0)) = s.seed;
  Int64_val(Field(sr_state_val,1)) = s.odd_gamma;
  
  CAMLreturn(Val_unit);
}