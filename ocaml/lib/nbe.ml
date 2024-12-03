type value

type vexp

type gexp =
 | Size
 | GenInt
 | Return of value
 | Bind of gexp * (value -> gexp)
 | WithSize of vexp * gexp
 | Fix of (gexp -> gexp)

type ne =
  | NSize
  | NGenInt of (vexp option)
  | NGenRec of nf * (vexp option)
and nf =
  | NReturn of value
  | NBind of ne * (value -> nf)
  | NFix of (nf -> nf)

type ty 