#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

// Define the struct
typedef struct state {
  int64_t seed;
  int64_t odd_gamma;
} state_t;

// Custom operations for handling the state struct
static void finalize_state(value v) {
  state_t *s = (state_t*)Data_custom_val(v);
  free(s);
}

static struct custom_operations state_ops = {
  .identifier = "state_ops",
  .finalize = finalize_state,
  .compare = custom_compare_default,
  .hash = custom_hash_default,
  .serialize = custom_serialize_default,
  .deserialize = custom_deserialize_default
};

// Constructor
CAMLprim value create_state(value seed, value gamma) {
  CAMLparam2(seed, gamma);
  CAMLlocal1(result);
  
  state_t *s = malloc(sizeof(state_t));
  s->seed = Int64_val(seed);
  s->odd_gamma = Int64_val(gamma);
  
  result = caml_alloc_custom(&state_ops, sizeof(state_t), 0, 1);
  memcpy(Data_custom_val(result), s, sizeof(state_t));
  free(s);
  
  CAMLreturn(result);
}

// CAMLprim value get_seed(value state_val) {
//   CAMLparam1(state_val);
//   state_t *s = Data_custom_val(state_val);
//   CAMLreturn(caml_copy_int64(s->seed));
// }

// CAMLprim value get_gamma(value state_val) {
//   CAMLparam1(state_val);
//   state_t *s = Data_custom_val(state_val);
//   CAMLreturn(caml_copy_int64(s->odd_gamma));
// }

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

CAMLprim value bool_c(value state_val) {
  CAMLparam1(state_val);
  state_t *st = Data_custom_val(state_val);
  int64_t draw = next_int64(st);
  bool result = (draw | 1L) == draw;
  CAMLreturn(Val_bool(result));
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
    draw = next_int64(st) & INT64_MAX; // is this the right int max? Want 64 bit
    remainder = draw % (max + 1);
  } while (!remainder_is_unbiased(draw,remainder,INT64_MAX,max));
  return remainder;
}

CAMLprim value int_c_unchecked(value state_val, value lo_val, value hi_val) {
  CAMLparam3(state_val,lo_val,hi_val);
  state_t *st = Data_custom_val(state_val);

  int64_t lo = (int64_t) Int_val(lo_val);
  int64_t hi = (int64_t) Int_val(hi_val);

  int64_t diff = hi - lo;
  int64_t result;
  if(diff == INT64_MAX){
    result = ((next_int64(st) & INT64_MAX) + lo);
  } else if (diff >= 0){
    result = non_negative_up_to(st,diff) + lo;
  } else {
    result = between(st,lo,hi);
  }
  CAMLreturn(Val_int(result));
}

CAMLprim value print(value state_val) {
  CAMLparam1(state_val);
  state_t *st = Data_custom_val(state_val);
  printf("C-Seed: %ld\n", st->seed);
  CAMLreturn(Val_unit);
}