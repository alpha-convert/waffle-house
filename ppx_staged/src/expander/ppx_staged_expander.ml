open! Import
open! Fast_gen;;
open Base;;

let compound_generator ~loc ~make_compound_expr generator_list =
  let rec go gs acc =
    match gs with
    | [] -> [%expr C_SR.return [%e make_compound_expr ~loc acc]]
    | g::gs -> 
      let x_pat, x_expr = gensym "x" loc in
      [%expr 
        C_SR.bind [%e g] ~f:(fun [%p x_pat] -> [%e go gs (x_expr :: acc)])
      ] 
  in go (List.rev generator_list) []

let compound
      (type field)
      ~generator_of_core_type
      ~loc
      ~fields
      (module Field : Field_syntax.S with type ast = field)
  =
  let fields = List.map fields ~f:Field.create in
  compound_generator
    ~loc
    ~make_compound_expr:(Field.expression fields)
    (List.map fields ~f:(fun field -> generator_of_core_type (Field.core_type field)))
;;

let does_refer_to name_set =
  object (self)
    inherit [bool] Ast_traverse.fold as super

    method! core_type ty acc =
      match ty.ptyp_desc with
      | Ptyp_constr (name, args) ->
        acc
        || Set.mem name_set (Longident.name name.txt)
        || List.exists args ~f:(fun arg -> self#core_type arg false)
      | _ -> super#core_type ty acc
  end
;;

let clause_is_recursive
      (type clause)
      ~clause
      ~rec_names
      (module Clause : Clause_syntax.S with type t = clause)
  =
  List.exists (Clause.core_type_list clause) ~f:(fun ty ->
    (does_refer_to rec_names)#core_type ty false)
;;

let generator_for_type ~loc type_name =
  let generator_name = Printf.sprintf "staged_quickcheck_generator_%s" type_name in
  [%expr generator_name]

let variant
  (type clause)
  ~generator_of_core_type
  ~loc
  ~variant_type
  ~clauses
  ~rec_names
  (module Clause : Clause_syntax.S with type ast = clause)
  =
  let clauses = Clause.create_list clauses in
  let make_generator clause =
    compound_generator
      ~loc:(Clause.location clause)
      ~make_compound_expr:(Clause.expression clause variant_type)
      (List.map (Clause.core_type_list clause) ~f:(fun typ -> match typ.ptyp_desc with
        | Ptyp_constr ({ txt = Lident "bool"; _ }, _) -> [%expr C_SR.bool]
        | Ptyp_constr ({ txt = Lident "float"; _}, _) -> [%expr C_SR.float ~lo:(C_SR.C.lift 0.0) ~hi:(C_SR.C.lift 1.0)]
        | Ptyp_constr ({ txt = Lident "int"; _}, _) -> [%expr C_SR.int]
        | Ptyp_constr ({ txt = id; _ }, _) ->
            (* Extract the last component of the longident for comparison *)
            let rec last_component = function
              | Longident.Lident s -> s
              | Longident.Ldot (_, s) -> s
              | Longident.Lapply (_, lid) -> last_component lid
            in
            let type_name = last_component id in
            
            (* Check if this is a recursive type reference *)
            if Set.mem rec_names type_name then
              [%expr C_SR.recurse go (C_SR.C.lift ())]
            else
              (* Call the appropriate generator for this non-recursive type *)
              Ast_helper.Exp.ident ~loc { loc = Location.none; txt = Longident.Lident ("staged_quickcheck_generator_" ^ type_name) }
              | _ -> [%expr C_SR.recurse go (C_SR.C.lift ())]
      ))
  in
  let make_pair clause =
    Option.map (Clause.weight clause) ~f:(fun weight ->
      pexp_tuple
        ~loc:{ (Clause.location clause) with loc_ghost = true }
        [ weight; make_generator clause ])
  in
  (* We filter out clauses with weight None now. If we don't, then we can get code in
   [body] below that relies on bindings that don't get generated. *)
  let clauses =
    List.filter clauses ~f:(fun clause -> Option.is_some (Clause.weight clause))
  in
  match
    List.partition_tf clauses ~f:(fun clause ->
      clause_is_recursive ~clause ~rec_names (module Clause))
  with
  | [], [] -> invalid ~loc "variant had no (generated) cases"
  | clauses, [] | [], clauses ->
      let pairs = List.filter_map clauses ~f:make_pair in
      [%expr
        C_SR.weighted_union
          [%e elist ~loc pairs]]
  | recursive_clauses, nonrecursive_clauses ->
      let size_pat, size_expr = gensym "size" loc in
      let nonrec_pat, nonrec_expr = gensym "gen" loc in
      let rec_pat, rec_expr = gensym "gen" loc in
      let nonrec_pats, nonrec_exprs =
        gensyms "pair" (List.map nonrecursive_clauses ~f:Clause.location)
      in
      let rec_pats, rec_exprs =
        gensyms "pair" (List.map recursive_clauses ~f:Clause.location)
      in
      let bindings =
        List.filter_opt
          (List.map2_exn nonrec_pats nonrecursive_clauses ~f:(fun pat clause ->
            let loc = { (Clause.location clause) with loc_ghost = true } in
            Option.map (make_pair clause) ~f:(fun expr -> value_binding ~loc ~pat ~expr))
          @ List.map2_exn rec_pats recursive_clauses ~f:(fun pat clause ->
            Option.map (Clause.weight clause) ~f:(fun weight_expr ->
              let loc = { (Clause.location clause) with loc_ghost = true } in
              let gen_expr =
                [%expr
                  C_SR.bind
                    C_SR.size
                    ~f:(fun [%p size_pat] ->
                      C_SR.with_size
                        ~size_c:(C_SR.C.pred [%e size_expr])
                        [%e make_generator clause])]
              in
              let expr = pexp_tuple ~loc [ weight_expr; gen_expr ] in
              value_binding ~loc ~pat ~expr)))
      in
      let body =
        [%expr
          let [%p nonrec_pat] =
            C_SR.weighted_union
              [%e elist ~loc nonrec_exprs]
          and [%p rec_pat] =
            C_SR.weighted_union
              [%e elist ~loc (nonrec_exprs @ rec_exprs)]
          in
          [%e
            [%expr
              C_SR.bind
                C_SR.size
                ~f:(fun x -> C_SR.if_z x [%e nonrec_expr] [%e rec_expr])]]]
      in
      [%expr C_SR.recursive ((C_SR.C.lift ())) (fun go _ -> [%e pexp_let ~loc Nonrecursive bindings body])]
;;

type impl =
  { loc : location
  ; typ : core_type
  ; pat : pattern
  ; var : expression
  ; exp : expression
  }

let rec generator_of_core_type core_type ~gen_env ~obs_env =
  let loc = { core_type.ptyp_loc with loc_ghost = true } in
  let gen_of_type ty =
    match ty.ptyp_desc with
    | Ptyp_constr ({ txt = Lident "bool"; _ }, _) -> Some [%expr C_SR.bool]
    | Ptyp_constr ({ txt = Lident "int"; _ }, _) -> Some [%expr C_SR.int]
    | Ptyp_constr ({ txt = Lident "float"; _ }, _) -> Some [%expr C_SR.float ~lo:(C_SR.C.lift 0.0) ~hi:(C_SR.C.lift 1.0)]
    | _ -> None
  in
  match gen_of_type core_type with
  | Some expr -> expr
  | None ->
    (match core_type.ptyp_desc with
     | Ptyp_constr (constr, args) ->
       type_constr_conv
         ~loc
         ~f:generator_name
         constr
         (List.map args ~f:(generator_of_core_type ~gen_env ~obs_env))
     | Ptyp_var tyvar -> Environment.lookup gen_env ~loc ~tyvar
     | Ptyp_arrow (arg_label, input_type, output_type) -> unsupported ~loc "Arrow types are not supported, %s" (short_string_of_core_type core_type)
     | Ptyp_tuple labeled_fields ->
          compound 
            ~generator_of_core_type:(generator_of_core_type ~gen_env ~obs_env)
            ~loc
            ~fields:labeled_fields
            (module Field_syntax.Tuple)
     | Ptyp_variant (clauses, Closed, None) -> variant
         ~generator_of_core_type:(generator_of_core_type ~gen_env ~obs_env)
         ~loc
         ~variant_type:core_type
         ~clauses
         ~rec_names:(Set.empty (module String))
         (module Clause_syntax.Polymorphic_variant)
     | Ptyp_variant (_, Open, _) -> unsupported ~loc "polymorphic variant type with [>]"
     | Ptyp_variant (_, _, Some _) -> unsupported ~loc "polymorphic variant type with [<]"
     | Ptyp_extension (tag, payload) -> unsupported ~loc "No custom extensions allowed!"
     | Ptyp_any
     | Ptyp_object _
     | Ptyp_class _
     | Ptyp_alias _
     | Ptyp_poly _
     | Ptyp_package _ -> unsupported ~loc "%s" (short_string_of_core_type core_type))

let generator_impl type_decl ~rec_names =
  let loc = type_decl.ptype_loc in
  let typ =
    combinator_type_of_type_declaration type_decl ~f:(fun ~loc ty ->
      [%type: [%t ty] C_SR.c C_SR.t])
  in
  let pat = pgenerator type_decl.ptype_name in
  let var = egenerator type_decl.ptype_name in
  let exp =
    let pat_list, `Covariant gen_env, `Contravariant obs_env =
      Environment.create_with_variance
        ~loc
        ~covariant:"generator"
        ~contravariant:"observer"
        type_decl.ptype_params
    in
    let body =
      match type_decl.ptype_kind with
      | Ptype_open -> unsupported ~loc "open type"
      | Ptype_variant clauses ->
        variant
          ~generator_of_core_type:(generator_of_core_type ~gen_env ~obs_env)
          ~loc
          ~variant_type:[%type: _]
          ~clauses
          ~rec_names
          (module Clause_syntax.Variant)
      | Ptype_record fields -> unsupported ~loc "record type"
        (*
        Ppx_generator_expander.compound
          ~generator_of_core_type:(generator_of_core_type ~gen_env ~obs_env)
          ~loc
          ~fields
          (module Field_syntax.Record)
        *)
      | Ptype_abstract ->
        (match type_decl.ptype_manifest with
         | Some core_type -> generator_of_core_type core_type ~gen_env ~obs_env
         | None -> unsupported ~loc "abstract type")
    in
    List.fold_right pat_list ~init:body ~f:(fun pat body ->
      [%expr fun [%p pat] -> [%e body]])
  in
  { loc; typ; pat; var; exp }
;;

let close_the_loop ~of_lazy decl impl =
  let loc = impl.loc in
  let exp = impl.var in
  match decl.ptype_params with
  | [] -> [%expr [%e exp]]
  | params ->
    let pats, exps =
      gensyms "recur" (List.map params ~f:(fun (core_type, _) -> core_type.ptyp_loc))
    in
    eabstract
      ~loc
      pats
      [%expr
          [%e
            eapply
              ~loc
              (eapply ~loc [%expr ()] [ exp ])
              exps]]
;;

let maybe_mutually_recursive decls ~loc ~rec_flag ~of_lazy ~impl =
  let decls = List.map decls ~f:name_type_params_in_td in
  let rec_names =
    match rec_flag with
    | Nonrecursive -> Set.empty (module String)
    | Recursive ->
      Set.of_list (module String) (List.map decls ~f:(fun decl -> decl.ptype_name.txt))
  in
  let impls = List.map decls ~f:(fun decl -> impl decl ~rec_names) in
  match rec_flag with
  | Nonrecursive ->
    pstr_value_list
      ~loc
      Nonrecursive
      (List.map impls ~f:(fun impl ->
         value_binding ~loc:impl.loc ~pat:impl.pat ~expr:impl.exp))
  | Recursive ->
    let recursive_bindings =
      let inner_bindings =
        List.map2_exn decls impls ~f:(fun decl inner ->
          value_binding
            ~loc:inner.loc
            ~pat:inner.pat
            ~expr:(close_the_loop ~of_lazy decl inner))
      in
      let rec wrap exp =
        match exp.pexp_desc with
        | Pexp_fun (arg_label, default, pat, body) ->
          { exp with pexp_desc = Pexp_fun (arg_label, default, pat, wrap body) }
        | _ ->
          exp
      in
      List.map2_exn decls impls ~f:(fun decl impl ->
        let body = wrap impl.exp in
        let lazy_expr = [%expr [%e body]] in
        (* Use the raw pattern without type constraint *)
        value_binding ~loc:impl.loc ~pat:impl.pat ~expr:lazy_expr)
    in
    [%str
      include struct
        open [%m pmod_structure ~loc (pstr_value_list ~loc Nonrecursive recursive_bindings)]
        [%%i
          pstr_value
            ~loc
            Nonrecursive
            (List.map2_exn decls impls ~f:(fun decl impl ->
               value_binding ~loc ~pat:impl.pat ~expr:(close_the_loop ~of_lazy decl impl)))]
      end]
;;

let generator_impl_list decls ~loc ~rec_flag =
  maybe_mutually_recursive
    decls
    ~loc
    ~rec_flag
    ~of_lazy:[%expr ()]
    ~impl:generator_impl
;;

let intf type_decl ~f ~covar ~contravar =
  let covar =
    Longident.parse ("Ppx_quickcheck_runtime.Base_quickcheck." ^ covar ^ ".t")
  in
  let contravar =
    Longident.parse ("Ppx_quickcheck_runtime.Base_quickcheck." ^ contravar ^ ".t")
  in
  let type_decl = name_type_params_in_td type_decl in
  let loc = type_decl.ptype_loc in
  let name = loc_map type_decl.ptype_name ~f in
  let result =
    ptyp_constr
      ~loc
      { loc; txt = covar }
      [ ptyp_constr
          ~loc
          (lident_loc type_decl.ptype_name)
          (List.map type_decl.ptype_params ~f:fst)
      ]
  in
  let type_ =
    List.fold_right
      type_decl.ptype_params
      ~init:result
      ~f:(fun (core_type, (variance, _)) result ->
        let id =
          match variance with
          | NoVariance | Covariant -> covar
          | Contravariant -> contravar
        in
        let arg = ptyp_constr ~loc { loc; txt = id } [ core_type ] in
        [%type: [%t arg] -> [%t result]])
  in
  psig_value ~loc (value_description ~loc ~name ~type_ ~prim:[])
;;

let generator_intf = intf ~f:generator_name ~covar:"Generator" ~contravar:"Observer"
let generator_intf_list type_decl_list = List.map type_decl_list ~f:generator_intf

let sig_type_decl =
  Deriving.Generator.make_noarg (fun ~loc ~path:_ (_, decls) ->
      generator_intf_list decls)
;;

let str_type_decl =
  Deriving.Generator.make_noarg (fun ~loc ~path:_ (rec_flag, decls) ->
    let rec_flag = really_recursive rec_flag decls in
    generator_impl_list ~loc ~rec_flag decls)
;;
