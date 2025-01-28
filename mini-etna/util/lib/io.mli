val bmain :
  string ->
  out_channel ->
  string ->
  (string * 'a Runner.property) list ->
  string ->
  (string * 'a Runner.basegen) list ->
  unit

val main :
  string ->
  (string * 'a Runner.property) list ->
  (string * 'a QCheck.arbitrary) list ->
  (string * 'a Crowbar.gen) list ->
  (string * 'a Runner.basegen) list ->
  unit

val etna :
  string ->
  (string * 'a Runner.property) list ->
  (string * 'a QCheck.arbitrary) list ->
  (string * 'a Crowbar.gen) list ->
  (string * 'a Runner.basegen) list ->
  unit

val timeout : int ref