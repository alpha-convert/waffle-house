type t = Leaf | Node of t * int * int * t

let rec insert k v t =
  match t with
  | Leaf -> Node (Leaf,k,v,Leaf)
  | Node (l,k',v',r) ->
    if k < k' then Node (insert k v l,k',v',r) else
    if k > k' then Node (l,k',v',insert k v r) else
    Node (l,k',v',r) (*BUG! should be v*)

let rec find (k : int) t =
  match t with
  | Leaf -> None
  | Node (l,k',v,r) ->
      if k == k' then Some v else
      if k < k' then find k l else find k r

open Base_quickcheck.Generator;;
open Base_quickcheck.Generator.Let_syntax;;

let g_basic =
  let rec go ~lo ~hi () =
    let%bind n = size in
    if lo >= hi || n <= 1 then return Leaf
    else
      weighted_union [
        (1.0, return Leaf);
        (Int.to_float n,
          let%bind k = int_inclusive lo hi in
          let%bind v = int_inclusive 0 100 in
          let%bind l = with_size ~size:(n / 2) (go ~lo:lo ~hi:k ()) in
          let%bind r = with_size ~size:(n / 2) (go ~lo:k ~hi:hi ()) in
          return (Node (l,k,v,r))
        )
      ]
  in
  let%bind n = size in
  go ~lo:0 ~hi:n ()


let g_fast =
  let rec go ~lo ~hi ~size ~random =
    if lo >= hi || size <= 1 then Leaf
    else
      let x = Splittable_random.int ~lo:0 ~hi:(size + 1) random in
      if x < 1 then Leaf else
        let v = Splittable_random.int ~lo:0 ~hi:100 random in
        let k = Splittable_random.int ~lo:0 ~hi:(size + 1) random in
        let l = go ~lo:lo ~hi:k ~size:(size / 2) ~random in
        let r = go ~lo:k ~hi:hi ~size:(size / 2) ~random in
        Node (l,k,v,r)
  in
  let%bind n = size in
  create (go ~lo:0 ~hi:n)


let shrink = Base_quickcheck.Shrinker.atomic

exception InvariantFail

let invariant t =
  let rec go lo hi t =
    match t with
    | Leaf -> true
    | Node (l,k,_,r) ->
        lo <= k && k <= hi && go (min k lo) k l && go k (max k hi) r
  in
  if not (go min_int max_int t) then raise InvariantFail

let g_insert_input_fast =
  create (fun ~size ~random ->
    let k = Splittable_random.int ~lo:0 ~hi:size random in
    let v = Splittable_random.int ~lo:0 ~hi:100 random in
    let t = generate g_fast ~size ~random in
    (k,v,t)
  )
let g_insert_input =
  let%bind n = size in
  let%bind k = int_inclusive 0 n in
  let%bind v = int_inclusive 0 100 in
  let%bind t = g_basic in
  return (k,v,t)

let g_insert_post_input_fast =
  create (fun ~size ~random ->
    let k = Splittable_random.int ~lo:0 ~hi:size random in
    let k' = Splittable_random.int ~lo:0 ~hi:size random in
    let v = Splittable_random.int ~lo:0 ~hi:100 random in
    let t = generate g_fast ~size ~random in
    (k,k',v,t)
  )
let g_insert_post_input =
  let%bind n = size in
  let%bind k = int_inclusive 0 n in
  let%bind k' = int_inclusive 0 n in
  let%bind v = int_inclusive 0 100 in
  let%bind t = g_basic in
  return (k,k',v,t)

