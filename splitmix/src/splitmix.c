#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/custom.h>

typedef struct state_t {
    uint64_t seed;
    uint64_t odd_gamma;
} state_t;

uint64_t golden_gamma = 0x9e3779b97f4a7c15;

inline uint64_t _mix_bits(uint64_t z, uint64_t n) {
    return z ^ (z >> n);
}

uint64_t _mix64(uint64_t z){
    z = _mix_bits(z,33) * 0xff51afd7ed558ccd;
    z = _mix_bits(z,33) * 0xc4ceb9fe1a85ec53;
    return _mix_bits(z,33);
}

uint64_t _next_seed(state_t *t){
    uint64_t next = t->seed + t->odd_gamma;
    t->seed = next;
    return next;
}

uint64_t _next_int64(state_t *t) {
    uint64_t next = _next_seed(t);
    return _mix64(next);
}

#define state_t_val(v) (*((state_t *) Data_custom_val(v)))
#define state_t_ptr(v) (((state_t *) (Data_custom_val(v))))

struct custom_operations state_tops;


static value alloc_state_t(state_t s) {
  value v = caml_alloc_custom(&state_tops, sizeof(state_t *), 0, 1);
  state_t_val(v) = s;
  return v;
}

CAMLprim value of_int(value v) {
  CAMLparam1(v);
  int64_t n = Int64_val(v);
  state_t s;
  s.seed = n;
  s.odd_gamma = golden_gamma;
  CAMLreturn(alloc_state_t(s));
}

CAMLprim value bool(value v) {
  CAMLparam1(v);
  int64_t n = _next_int64(state_t_ptr(v)) % 2;
  CAMLreturn(Val_bool(n));
}

CAMLprim value intv(value v) {
  CAMLparam1(v);
  int64_t n = _next_int64(state_t_ptr(v));
  CAMLreturn(Val_long(n));
}

// // let next_int64 t = mix64 (next_seed t)



// // let mix_odd_gamma z =
// //   let z = mix64_variant13 z lor 1L in
// //   let n = popcount (z lxor (z lsr 1)) in
// //   (* The original paper uses [>=] in the conditional immediately below; however this is
// //      a typo, and we correct it by using [<]. This was fixed in response to [1] and [2].

// //      [1] https://github.com/janestreet/splittable_random/issues/1
// //      [2] http://www.pcg-random.org/posts/bugs-in-splitmix.html
// //   *)
// //   if Int.( < ) n 24 then z lxor 0xaaaa_aaaa_aaaa_aaaaL else z
// // ;;

// // let%test_unit "odd gamma" =
// //   for input = -1_000_000 to 1_000_000 do
// //     let output = mix_odd_gamma (Int64.of_int input) in
// //     if not (is_odd output)
// //     then Error.raise_s [%message "gamma value is not odd" (input : int) (output : int64)]
// //   done
// // ;;

// // let next_seed t =
// //   let next = t.seed + t.odd_gamma in
// //   t.seed <- next;
// //   next
// // ;;

// // let random_int64 random_state_t =
// //   Random.state_t.int64_incl random_state_t Int64.min_value Int64.max_value
// // ;;

// // let create random_state_t =
// //   let seed = random_int64 random_state_t in
// //   let gamma = random_int64 random_state_t in
// //   of_seed_and_gamma ~seed ~gamma
// // ;;

// // let split t =
// //   let seed = next_seed t in
// //   let gamma = next_seed t in
// //   of_seed_and_gamma ~seed ~gamma
// // ;;


// // (* [perturb] is not from any external source, but provides a way to mix in external
// //    entropy with a pseudo-random state_t. *)
// // let perturb t salt =
// //   let next = t.seed + mix64 (Int64.of_int salt) in
// //   t.seed <- next
// // ;;

// // let bool state_t = is_odd (next_int64 state_t)