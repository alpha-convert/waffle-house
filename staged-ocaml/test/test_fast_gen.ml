open Fast_gen.Codecps;;
open Fast_gen.Codecps.Let_syntax;;
module G = Fast_gen.Staged_generator;;

type tree = Empty | Node of tree * int * tree

let g = 
  G.bind G.size ~f:(fun n ->
    G.recursive .<(0,.~n)>. (
      fun rcall lohi ->
        _
    )
  )