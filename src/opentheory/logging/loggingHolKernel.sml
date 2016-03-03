structure HolKernel =
struct
  open HolKernel Logging
  fun new_theory s = let
    val _ = HolKernel.new_theory s
    val _ = start_logging s
    fun th {Thy,Tyop} =
      case (Thy,Tyop) of
          ("min", "fun") => ([], "->")
        | ("min", "bool") => ([], "bool")
        | _ => (["HOL4",Thy],Tyop)
    fun ch {Thy,Name} =
      case (Thy,Name) of
          ("min", "=") => ([], "=")
        | _ => (["HOL4",Thy],Name)
    val _ = set_tyop_name_handler th
    val _ = set_const_name_handler ch
  in () end

  fun export_theory() = let
    open Lib Theory
    val _ = map (export_thm o snd) (current_theorems())
    val _ = map (export_thm o snd) (current_definitions())
    val _ = map (export_thm o snd) (current_axioms())
    val _ = stop_logging()
  in () end
end
