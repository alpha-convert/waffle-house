open Custom;;

module Small = struct
  type t = custom_list
  [@@deriving sexp, quickcheck]
end
