open HolKernel Parse boolLib bossLib metisLib

val _ = new_theory "chap3";

local open pred_setLib in end;

open ncLib
open chap2Theory ncTheory swapTheory

val compatible_def =
    Define`compatible R = !x y c. R x y /\ one_hole_context c ==>
                                  R (c x) (c y)`;

val symmetric_def =
    Define`symmetric R = !x y. R x y ==> R y x`;

val equivalence_def =
    Define`equivalence R = reflexive R /\ symmetric R /\ transitive R`;

val congruence_def = Define`congruence R = equivalence R /\ compatible R`;

val is_reduction_def =
    Define`is_reduction R = compatible R /\ transitive R /\ reflexive R`;

val (compat_closure_rules, compat_closure_ind, compat_closure_cases) =
    Hol_reln`(!x y. R x y ==> compat_closure R x y) /\
             (!x y z. compat_closure R x y ==>
                      compat_closure R (z @@ x) (z @@ y)) /\
             (!x y z. compat_closure R x y ==>
                      compat_closure R (x @@ z) (y @@ z)) /\
             (!x y v. compat_closure R x y ==>
                 compat_closure R (LAM v x) (LAM v y))`

(* Barendregt definition 3.1.14 *)
val substitutive_def = Define`
  substitutive R = !M M'. R M M' ==> !N v. R ([N/v]M) ([N/v]M')
`;

val permutative_def = Define`
  permutative R = !M M'. R M M' ==> !x y. R (swap x y M) (swap x y M')
`;

val compat_closure_permutative = store_thm(
  "compat_closure_permutative",
  ``permutative R ==> permutative (compat_closure R)``,
  STRIP_TAC THEN ASM_SIMP_TAC (srw_ss()) [permutative_def] THEN
  HO_MATCH_MP_TAC compat_closure_ind THEN SRW_TAC [][swap_thm] THEN
  METIS_TAC [permutative_def, compat_closure_rules]);

val permutative_compat_closure_eqn = store_thm(
  "permutative_compat_closure_eqn",
  ``permutative R ==>
    (compat_closure R (swap x y M) (swap x y N) = compat_closure R M N)``,
  STRIP_TAC THEN EQ_TAC THEN STRIP_TAC THENL [
    `permutative (compat_closure R)`
       by METIS_TAC [compat_closure_permutative] THEN
    `compat_closure R (swap x y (swap x y M)) (swap x y (swap x y N))`
       by METIS_TAC [permutative_def] THEN
    FULL_SIMP_TAC (srw_ss()) [swap_inverse],
    METIS_TAC [permutative_def, compat_closure_permutative]
  ]);
val _ = BasicProvers.export_rewrites ["permutative_compat_closure_eqn"]

val swap_eq_3substs = store_thm(
  "swap_eq_3substs",
  ``~(z IN FV M) /\ ~(x = z) /\ ~(y = z) ==>
    (swap x y M = [VAR y/z] ([VAR x/y] ([VAR z/x] M)))``,
  SRW_TAC [][fresh_var_swap] THEN
  `swap x y (swap z x M) = swap (swapstr x y z) (swapstr x y x) (swap x y M)`
     by SRW_TAC [][] THEN
  POP_ASSUM SUBST_ALL_TAC THEN
  ONCE_REWRITE_TAC [GSYM swap_swap] THEN
  ASM_SIMP_TAC bool_ss [swapstr_def] THEN
  SRW_TAC [][]);

val substitutive_implies_permutative = store_thm(
  "substitutive_implies_permutative",
  ``substitutive R ==> permutative R``,
  SRW_TAC [][substitutive_def, permutative_def] THEN
  Q_TAC (NEW_TAC "z") `{x; y} UNION FV M UNION FV M'` THEN
  `(swap x y M = [VAR y/z] ([VAR x/y] ([VAR z/x] M))) /\
   (swap x y M'= [VAR y/z] ([VAR x/y] ([VAR z/x] M')))`
      by SRW_TAC [][swap_eq_3substs] THEN
  ASM_SIMP_TAC (srw_ss()) []);


val compat_closure_substitutive = store_thm(
  "compat_closure_substitutive",
  ``substitutive R ==> substitutive (compat_closure R)``,
  STRIP_TAC THEN SIMP_TAC (srw_ss()) [substitutive_def] THEN
  HO_MATCH_MP_TAC compat_closure_ind THEN SRW_TAC [][SUB_THM] THENL [
    PROVE_TAC [compat_closure_rules, substitutive_def],
    PROVE_TAC [compat_closure_rules],
    PROVE_TAC [compat_closure_rules],
    Q_TAC (NEW_TAC "z") `{v;v'} UNION FV M UNION FV M' UNION FV N` THEN
    `(LAM v M = LAM z (swap z v M)) /\ (LAM v M' = LAM z (swap z v M'))`
       by SRW_TAC [][swap_ALPHA] THEN
    ASM_SIMP_TAC (srw_ss()) [SUB_THM, swap_subst_out] THEN
    MATCH_MP_TAC (last (CONJUNCTS (SPEC_ALL compat_closure_rules))) THEN
    `permutative R` by METIS_TAC [substitutive_implies_permutative] THEN
    ASM_SIMP_TAC (srw_ss()) []
  ]);

val (equiv_closure_rules, equiv_closure_ind, equiv_closure_cases) =
    Hol_reln`(!x y. R x y ==> equiv_closure R x y) /\
             (!x. equiv_closure R x x) /\
             (!x y. equiv_closure R x y ==> equiv_closure R y x) /\
             (!x y z. equiv_closure R x y /\ equiv_closure R y z ==>
                      equiv_closure R x z)`;

val equiv_closure_substitutive = store_thm(
  "equiv_closure_substitutive",
  ``substitutive R ==> substitutive (equiv_closure R)``,
  STRIP_TAC THEN SIMP_TAC (srw_ss()) [substitutive_def] THEN
  HO_MATCH_MP_TAC equiv_closure_ind THEN SRW_TAC [][] THEN
  METIS_TAC [substitutive_def, equiv_closure_rules]);

val conversion_def =
    Define`conversion R = equiv_closure (compat_closure R)`;

val conversion_substitutive = store_thm(
  "conversion_substitutive",
  ``substitutive R ==> substitutive (conversion R)``,
  METIS_TAC [compat_closure_substitutive, equiv_closure_substitutive,
             conversion_def]);

val RTC_substitutive = store_thm(
  "RTC_substitutive",
  ``substitutive R ==> substitutive (RTC R)``,
  STRIP_TAC THEN SIMP_TAC (srw_ss()) [substitutive_def] THEN
  HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN
  METIS_TAC [relationTheory.RTC_RULES, substitutive_def]);

val reduction_def =
    Define`reduction R = RTC (compat_closure R)`;

val reduction_substitutive = store_thm(
  "reduction_substitutive",
  ``substitutive R ==> substitutive (reduction R)``,
  METIS_TAC [compat_closure_substitutive, RTC_substitutive, reduction_def]);

val conversion_rules = store_thm(
  "conversion_rules",
  ``!R. (!x. conversion R x x) /\
        (!x y. conversion R x y ==> conversion R y x) /\
        (!x y z. conversion R x y /\ conversion R y z ==> conversion R x z) /\
        (!x y. R x y ==> conversion R x y) /\
        (!x y. reduction R x y ==> conversion R x y) /\
        (!x y. compat_closure R x y ==> conversion R x y)``,
  SRW_TAC [][equiv_closure_rules, conversion_def] THENL [
    PROVE_TAC [equiv_closure_rules],
    PROVE_TAC [equiv_closure_rules, compat_closure_rules],
    POP_ASSUM MP_TAC THEN SIMP_TAC (srw_ss()) [reduction_def] THEN
    MAP_EVERY Q.ID_SPEC_TAC [`y`,`x`] THEN
    HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN
    PROVE_TAC [equiv_closure_rules]
  ]);

val compat_closure_compatible = store_thm(
  "compat_closure_compatible",
  ``!R. compatible (compat_closure R)``,
  GEN_TAC THEN
  Q_TAC SUFF_TAC `!c. one_hole_context c ==>
                      !x y. compat_closure R x y ==>
                            compat_closure R (c x) (c y)` THEN1
     SRW_TAC [][compatible_def] THEN
  HO_MATCH_MP_TAC one_hole_context_ind THEN SRW_TAC [][] THEN
  PROVE_TAC [compat_closure_rules]);

val reduction_compatible = store_thm(
  "reduction_compatible",
  ``!R. compatible (reduction R)``,
  GEN_TAC THEN
  Q_TAC SUFF_TAC `!x y. RTC (compat_closure R) x y ==>
                        !c. one_hole_context c ==>
                            RTC (compat_closure R) (c x) (c y)` THEN1
    SRW_TAC [][compatible_def, reduction_def] THEN
  HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN SRW_TAC [][] THENL [
    PROVE_TAC [relationTheory.RTC_RULES],
    PROVE_TAC [compatible_def, compat_closure_compatible,
               relationTheory.RTC_RULES]
  ]);

val reduction_rules = store_thm(
  "reduction_rules",
  ``(!x. reduction R x x) /\
    (!x y. R x y ==> reduction R x y) /\
    (!x y. compat_closure R x y ==> reduction R x y) /\
    (!x y z. reduction R x y /\ reduction R y z ==>
             reduction R x z) /\
    (!x y z. reduction R x y ==> reduction R (z @@ x) (z @@ y)) /\
    (!x y z. reduction R x y ==> reduction R (x @@ z) (y @@ z)) /\
    (!x y v. reduction R x y ==> reduction R (LAM v x) (LAM v y))``,
  REPEAT STRIP_TAC THENL [
    PROVE_TAC [reduction_def, relationTheory.RTC_RULES],
    PROVE_TAC [reduction_def, relationTheory.RTC_RULES, compat_closure_rules],
    PROVE_TAC [reduction_def, relationTheory.RTC_RULES],
    PROVE_TAC [reduction_def, relationTheory.RTC_RTC],
    PROVE_TAC [leftctxt, compatible_def, reduction_compatible],
    PROVE_TAC [rightctxt_thm, rightctxt, compatible_def, reduction_compatible],
    PROVE_TAC [absctxt, compatible_def, reduction_compatible]
  ]);

val conversion_compatible = store_thm(
  "conversion_compatible",
  ``!R. compatible (conversion R)``,
  GEN_TAC THEN
  Q_TAC SUFF_TAC `!x y. equiv_closure (compat_closure R) x y ==>
                        !c. one_hole_context c ==>
                            equiv_closure (compat_closure R) (c x) (c y)` THEN1
    SRW_TAC [][compatible_def, conversion_def] THEN
  HO_MATCH_MP_TAC equiv_closure_ind THEN SRW_TAC [][] THEN
  PROVE_TAC [compatible_def, equiv_closure_rules, compat_closure_compatible]);

(* "Follows from an induction on the structure of M, and the
    compatibility of reduction R" *)
val lemma3_8 = store_thm(
  "lemma3_8",
  ``!R M N N'. reduction R N N' ==> reduction R ([N/x] M) ([N'/x] M)``,
  GEN_TAC THEN HO_MATCH_MP_TAC nc_INDUCTION THEN
  SRW_TAC [][SUB_THM, SUB_VAR] THENL [
    PROVE_TAC [reduction_rules],
    PROVE_TAC [reduction_rules],
    PROVE_TAC [reduction_rules],
    Q_TAC (NEW_TAC "z") `FV M UNION FV N UNION FV N' UNION {x; x'}` THEN
    `LAM x' M = LAM z ([VAR z/x'] M)` by SRW_TAC [][SIMPLE_ALPHA] THEN
    ASM_SIMP_TAC (srw_ss()) [SUB_THM] THEN PROVE_TAC [reduction_rules]
  ]);

val redex_def = Define`redex (R:'a -> 'a -> bool) t = ?u. R t u`;

val (can_reduce_rules, can_reduce_ind, can_reduce_cases) =
  Hol_reln`(!t. redex R t ==> can_reduce R t) /\
           (!M N. can_reduce R M ==> can_reduce R (M @@ N)) /\
           (!M N. can_reduce R M ==> can_reduce R (N @@ M)) /\
           (!v M. can_reduce R M ==> can_reduce R (LAM v M))`

val can_reduce_reduces = store_thm(
  "can_reduce_reduces",
  ``!R t. can_reduce R t ==> ?u. compat_closure R t u``,
  GEN_TAC THEN HO_MATCH_MP_TAC can_reduce_ind THEN SRW_TAC [][redex_def] THEN
  PROVE_TAC [compat_closure_rules]);

val normal_form_def = Define`normal_form R t = ~can_reduce R t`;

(* definition from p30 *)
val beta_def = Define`beta M N = ?x body arg. (M = LAM x body @@ arg) /\
                                              (N = [arg/x]body)`;


val beta_substitutive = store_thm(
  "beta_substitutive",
  ``substitutive beta``,
  SRW_TAC [][substitutive_def, beta_def] THEN
  Q_TAC (NEW_TAC "z") `{v; x} UNION FV body UNION FV arg UNION FV N` THEN
  `LAM x body = LAM z ([VAR z/x] body)` by SRW_TAC [][SIMPLE_ALPHA] THEN
  Q.EXISTS_TAC `z` THEN SRW_TAC [][SUB_THM, GENERAL_SUB_COMMUTE]);

val cc_beta_subst = store_thm(
  "cc_beta_subst",
  ``!M N. compat_closure beta M N ==>
          !P v. compat_closure beta ([P/v]M) ([P/v]N)``,
  METIS_TAC [beta_substitutive, compat_closure_substitutive,
             substitutive_def]);

val reduction_beta_subst = store_thm(
  "reduction_beta_subst",
  ``!M N. reduction beta M N ==>
          !P v. reduction beta ([P/v]M) ([P/v]N)``,
  METIS_TAC [beta_substitutive, reduction_substitutive, substitutive_def]);

val cc_beta_FV_SUBSET = store_thm(
  "cc_beta_FV_SUBSET",
  ``!M N. compat_closure beta M N ==> FV N SUBSET FV M``,
  HO_MATCH_MP_TAC compat_closure_ind THEN
  SIMP_TAC (srw_ss() ++ boolSimps.COND_elim_ss)
           [pred_setTheory.SUBSET_DEF, beta_def,
            GSYM LEFT_FORALL_IMP_THM, FV_SUB] THEN
  PROVE_TAC []);

val cc_beta_thm = store_thm(
  "cc_beta_thm",
  ``(!s t. compat_closure beta (VAR s) t = F) /\
    (!k t. compat_closure beta (CON k) t = F) /\
    (!M N P. compat_closure beta (M @@ N) P =
               (?v M0. (M = LAM v M0) /\ (P = [N/v]M0)) \/
               is_comb P /\ compat_closure beta M (rator P) /\ (rand P = N) \/
               is_comb P /\ compat_closure beta N (rand P) /\ (rator P = M)) /\
    (!v (M:'a nc) N.
               compat_closure beta (LAM v M) N =
               ?N0. (N = LAM v N0) /\ compat_closure beta M N0)``,
  CONV_TAC (EVERY_CONJ_CONV
            (STRIP_QUANT_CONV
               (LAND_CONV (ONCE_REWRITE_CONV [compat_closure_cases])))) THEN
  SIMP_TAC (srw_ss()) [beta_def] THEN REPEAT STRIP_TAC THEN EQ_TAC THEN
  SRW_TAC [][] THENL [
    PROVE_TAC [],
    SRW_TAC [][is_comb_thm, rand_thm, rator_thm],
    SRW_TAC [][is_comb_thm, rand_thm, rator_thm],
    PROVE_TAC [],
    PROVE_TAC [is_comb_rator_rand],
    PROVE_TAC [is_comb_rator_rand],
    REPEAT (POP_ASSUM MP_TAC) THEN
    Q_TAC SUFF_TAC
          `!v w (M:'a nc) N P.
                       (LAM v M = LAM w N) ==>
                       compat_closure beta N P ==>
                       ?M0. (LAM w P = LAM v M0) /\
                            compat_closure beta M M0` THEN1 PROVE_TAC [] THEN
    REPEAT STRIP_TAC THEN
    Cases_on `v = w` THEN1 PROVE_TAC [LAM_VAR_INJECTIVE] THEN
    `~(v IN FV N) /\ ~(w IN FV M)` by PROVE_TAC [LAM_INJ_ALPHA_FV] THEN
    `M = [VAR v/w]N` by PROVE_TAC [INJECTIVITY_LEMMA1] THEN
    `compat_closure beta M ([VAR v/w]P)` by PROVE_TAC [cc_beta_subst] THEN
    `~(v IN FV P)` by PROVE_TAC [cc_beta_FV_SUBSET,
                                 pred_setTheory.SUBSET_DEF] THEN
    Q.EXISTS_TAC `[VAR v/w] P` THEN SRW_TAC [][SIMPLE_ALPHA],
    PROVE_TAC []
  ]);



val beta_normal_form_bnf = store_thm(
  "beta_normal_form_bnf",
  ``normal_form beta = bnf``,
  SIMP_TAC (srw_ss()) [FUN_EQ_THM, EQ_IMP_THM, normal_form_def,
                       FORALL_AND_THM] THEN
  CONJ_TAC THENL [
    Q_TAC SUFF_TAC `!t. ~bnf t ==> can_reduce beta t` THEN1 PROVE_TAC [] THEN
    HO_MATCH_MP_TAC nc_INDUCTION THEN SRW_TAC [][] THENL [
      PROVE_TAC [can_reduce_rules],
      PROVE_TAC [can_reduce_rules],
      Q_TAC SUFF_TAC `redex beta (t @@ t')` THEN1
            PROVE_TAC [can_reduce_rules] THEN
      SRW_TAC [][redex_def, beta_def] THEN PROVE_TAC [is_abs_thm, nc_CASES],
      PROVE_TAC [lemma14a, can_reduce_rules]
    ],
    Q_TAC SUFF_TAC `!t. can_reduce beta t ==> ~bnf t` THEN1 PROVE_TAC [] THEN
    HO_MATCH_MP_TAC can_reduce_ind THEN SRW_TAC [][redex_def, beta_def] THEN
    SRW_TAC [][]
  ]);

val nf_of_def = Define`nf_of R M N = normal_form R N /\ conversion R M N`;

val prop3_10 = store_thm(
  "prop3_10",
  ``!R M N.
       compat_closure R M N = ?P Q c. one_hole_context c /\ (M = c P) /\
                                      (N = c Q) /\ R P Q``,
  GEN_TAC THEN SIMP_TAC (srw_ss()) [EQ_IMP_THM, FORALL_AND_THM] THEN
  CONJ_TAC THENL [
    HO_MATCH_MP_TAC compat_closure_ind THEN SRW_TAC [][] THENL [
      MAP_EVERY Q.EXISTS_TAC [`M`,`N`,`\x.x`] THEN
      SRW_TAC [][one_hole_context_rules],
      MAP_EVERY Q.EXISTS_TAC [`P`,`Q`,`\t. z @@ c t`] THEN
      SRW_TAC [][one_hole_context_rules],
      MAP_EVERY Q.EXISTS_TAC [`P`,`Q`,`\t. c t @@ z`] THEN
      SRW_TAC [][one_hole_context_rules],
      MAP_EVERY Q.EXISTS_TAC [`P`,`Q`,`\t. LAM v (c t)`] THEN
      SRW_TAC [][one_hole_context_rules]
    ],
    PROVE_TAC [compat_closure_compatible, compatible_def,
               compat_closure_rules]
  ]);

val corollary3_2_1 = store_thm(
  "corollary3_2_1",
  ``!R M. normal_form R M ==> (!N. ~compat_closure R M N) /\
                              (!N. reduction R M N ==> (M = N))``,
  SIMP_TAC (srw_ss()) [normal_form_def] THEN REPEAT GEN_TAC THEN
  STRIP_TAC THEN
  Q.SUBGOAL_THEN `!N. ~compat_closure R M N` ASSUME_TAC THENL [
    GEN_TAC THEN POP_ASSUM MP_TAC THEN
    CONV_TAC CONTRAPOS_CONV THEN SIMP_TAC (srw_ss())[] THEN
    MAP_EVERY Q.ID_SPEC_TAC [`N`, `M`] THEN
    HO_MATCH_MP_TAC compat_closure_ind THEN
    PROVE_TAC [can_reduce_rules, redex_def],
    ALL_TAC
  ] THEN ASM_SIMP_TAC (srw_ss()) [reduction_def] THEN
  PROVE_TAC [relationTheory.RTC_CASES1]);

val diamond_property_def =
    Define`diamond_property R =
             !M M1 M2. R M M1 /\ R M M2 ==> ?M3. R M1 M3 /\ R M2 M3`;

val CR_def = Define`CR R = diamond_property (reduction R)`;

val theorem3_13 = store_thm(
  "theorem3_13",
  ``!R. CR R ==>
        !M N. conversion R M N ==> ?Z. reduction R M Z /\ reduction R N Z``,
  GEN_TAC THEN STRIP_TAC THEN SIMP_TAC (srw_ss()) [conversion_def] THEN
  HO_MATCH_MP_TAC equiv_closure_ind THEN REVERSE (SRW_TAC [][]) THEN1
    (`?Z2. reduction R Z Z2 /\ reduction R Z' Z2` by
        PROVE_TAC [CR_def, diamond_property_def] THEN
     PROVE_TAC [reduction_rules]) THEN
  PROVE_TAC [reduction_rules]);

val corollary3_3_1 = store_thm(
  "corollary3_3_1",
  ``!R. CR R ==> (!M N. nf_of R M N ==> reduction R M N) /\
                 (!M N1 N2. nf_of R M N1 /\ nf_of R M N2 ==> (N1 = N2))``,
  SRW_TAC [][nf_of_def] THENL [
    PROVE_TAC [corollary3_2_1, theorem3_13],
    `conversion R N1 N2` by
       (FULL_SIMP_TAC (srw_ss()) [conversion_def] THEN
        PROVE_TAC [equiv_closure_rules]) THEN
    `?Z. reduction R N1 Z /\ reduction R N2 Z` by
       PROVE_TAC [theorem3_13] THEN
    PROVE_TAC [corollary3_2_1]
  ]);

val diamond_TC = store_thm(
  "diamond_TC",
  ``!R. diamond_property R ==> diamond_property (TC R)``,
  REPEAT STRIP_TAC THEN SIMP_TAC (srw_ss()) [diamond_property_def] THEN
  Q_TAC SUFF_TAC `!M M1. TC R M M1 ==>
                         !M2. TC R M M2 ==>
                              ?M3. TC R M1 M3 /\ TC R M2 M3` THEN1
    PROVE_TAC [] THEN
  HO_MATCH_MP_TAC relationTheory.TC_INDUCT THEN REPEAT CONJ_TAC THENL [
    Q_TAC SUFF_TAC `!x M2. TC R x M2 ==>
                           !y. R x y ==> ?M3. TC R y M3 /\ TC R M2 M3` THEN1
      PROVE_TAC [] THEN
    HO_MATCH_MP_TAC relationTheory.TC_INDUCT_LEFT1 THEN
    PROVE_TAC [diamond_property_def, relationTheory.TC_RULES],
    PROVE_TAC [diamond_property_def, relationTheory.TC_RULES]
  ]);


val (grandbeta_rules, grandbeta_ind, grandbeta_cases) =
    Hol_reln`(!M. grandbeta M M) /\
             (!M M' x. grandbeta M M' ==> grandbeta (LAM x M) (LAM x M')) /\
             (!M N M' N'. grandbeta M M' /\ grandbeta N N' ==>
                          grandbeta (M @@ N) (M' @@ N')) /\
             (!M N M' N' x. grandbeta M M' /\ grandbeta N N' ==>
                            grandbeta ((LAM x M) @@ N) ([N'/x] M'))`;

val exercise3_3_1 = store_thm(
  "exercise3_3_1",
  ``!M N. compat_closure beta M N ==> grandbeta M N``,
  HO_MATCH_MP_TAC compat_closure_ind THEN SRW_TAC [][beta_def] THEN
  PROVE_TAC [grandbeta_rules]);

val app_grandbeta = store_thm(  (* property 3 on p. 37 *)
  "app_grandbeta",
  ``!M N L. grandbeta (M @@ N) L =
               (?M' N'. grandbeta M M' /\ grandbeta N N' /\ (L = M' @@ N')) \/
               (?x P P' N'. (M = LAM x P) /\ grandbeta P P' /\
                            grandbeta N N' /\ (L = [N'/x]P'))``,
  REPEAT GEN_TAC THEN EQ_TAC THENL [
    CONV_TAC (LAND_CONV (ONCE_REWRITE_CONV [grandbeta_cases])) THEN
    SIMP_TAC (srw_ss()) [nc_DISTINCT, nc_INJECTIVITY,
                         DISJ_IMP_THM, GSYM LEFT_FORALL_IMP_THM,
                         grandbeta_rules] THEN PROVE_TAC [],
    SRW_TAC [][] THEN PROVE_TAC [grandbeta_rules]
  ]);

val grandbeta_permutative = store_thm(
  "grandbeta_permutative",
  ``!M N. grandbeta M N ==> !x y. grandbeta (swap x y M) (swap x y N)``,
  HO_MATCH_MP_TAC grandbeta_ind THEN SRW_TAC [][swap_thm, swap_subst] THEN
  METIS_TAC [grandbeta_rules]);

val grandbeta_permutative_eqn = store_thm(
  "grandbeta_permutative_eqn",
  ``grandbeta (swap x y M) (swap x y N) = grandbeta M N``,
  METIS_TAC [swap_inverse, grandbeta_permutative]);
val _ = BasicProvers.export_rewrites ["grandbeta_permutative_eqn"]

val grandbeta_substitutive = store_thm(
  "grandbeta_substitutive",
  ``!M N x P. grandbeta M N ==> grandbeta ([P/x]M) ([P/x]N)``,
  SIMP_TAC (srw_ss()) [RIGHT_FORALL_IMP_THM] THEN
  HO_MATCH_MP_TAC grandbeta_ind THEN SRW_TAC [][SUB_THM] THENL [
    METIS_TAC [grandbeta_rules],
    Q_TAC (NEW_TAC "z") `{x;x'} UNION FV M UNION FV P UNION FV N` THEN
    `(LAM x M = LAM z (swap z x M)) /\ (LAM x N = LAM z (swap z x N))`
        by SRW_TAC [][swap_ALPHA] THEN
    SRW_TAC [][SUB_THM, swap_subst_out, grandbeta_rules],
    METIS_TAC [grandbeta_rules],
    Q_TAC (NEW_TAC "z") `{x; x'} UNION FV M UNION FV P UNION FV N'` THEN
    `LAM x M = LAM z (swap z x M)` by SRW_TAC [][swap_ALPHA] THEN
    SRW_TAC [][SUB_THM] THEN
    `grandbeta ([P/x'] (swap z x M)) ([P/x'] (swap z x N'))`
       by SRW_TAC [][swap_subst_out] THEN
    `grandbeta ([P/x'] M') ([P/x']N'')` by SRW_TAC [][] THEN
    Q_TAC SUFF_TAC
          `[[P/x']N'' / z] ([P/x'] (swap z x N')) =
           [P/x'] ([N''/x] N')` THEN1 METIS_TAC [grandbeta_rules] THEN
    SRW_TAC [][GSYM fresh_var_swap, GENERAL_SUB_COMMUTE]
  ]);

val grandbeta_FV = store_thm(
  "grandbeta_FV",
  ``!M N. grandbeta M N ==> FV N SUBSET FV M``,
  HO_MATCH_MP_TAC grandbeta_ind THEN
  SRW_TAC [][FV_THM, pred_setTheory.SUBSET_DEF, FV_SUB] THEN
  PROVE_TAC []);

val abs_grandbeta = store_thm(
  "abs_grandbeta",
  ``!M N v. grandbeta (LAM v M) N = ?N0. (N = LAM v N0) /\ grandbeta M N0``,
  REPEAT GEN_TAC THEN EQ_TAC THENL [
    CONV_TAC (LAND_CONV (ONCE_REWRITE_CONV [grandbeta_cases])) THEN
    SIMP_TAC (srw_ss()) [nc_DISTINCT, DISJ_IMP_THM, LAM_VAR_INJECTIVE,
                         grandbeta_rules] THEN SRW_TAC [][] THEN
    Cases_on `v = x` THEN FULL_SIMP_TAC (srw_ss()) [LAM_VAR_INJECTIVE] THEN
    `~(v IN FV M') /\ ~(x IN FV M)` by PROVE_TAC [LAM_INJ_ALPHA_FV] THEN
    Q.EXISTS_TAC `[VAR v/x]M''` THEN
    IMP_RES_TAC INJECTIVITY_LEMMA1 THEN SRW_TAC [][] THENL [
      `~(v IN FV M'')` by
         PROVE_TAC [pred_setTheory.SUBSET_DEF, grandbeta_FV] THEN
      PROVE_TAC [SIMPLE_ALPHA],
      PROVE_TAC [grandbeta_substitutive]
    ],
    PROVE_TAC [grandbeta_rules]
  ]);

val lemma3_15 = save_thm("lemma3_15", abs_grandbeta);

val con_grandbeta = store_thm(
  "con_grandbeta",
  ``!k N. grandbeta (CON k) N = (N = CON k)``,
  REPEAT GEN_TAC THEN ONCE_REWRITE_TAC [grandbeta_cases] THEN
  SRW_TAC [][nc_DISTINCT]);

val var_grandbeta = store_thm(
  "var_grandbeta",
  ``!v N. grandbeta (VAR v) N = (N = VAR v)``,
  REPEAT GEN_TAC THEN ONCE_REWRITE_TAC [grandbeta_cases] THEN
  SRW_TAC [][]);

val grandbeta_cosubstitutive = store_thm(
  "grandbeta_cosubstitutive",
  ``!M N x. grandbeta N N' ==> grandbeta ([N/x] M) ([N'/x] M)``,
  HO_MATCH_MP_TAC nc_INDUCTION THEN
  SRW_TAC [][SUB_THM, grandbeta_rules, SUB_VAR] THEN
  Q_TAC (NEW_TAC "z") `{x'; x} UNION FV N UNION FV N' UNION FV M` THEN
  `LAM x M = LAM z ([VAR z/x] M)` by SRW_TAC [][SIMPLE_ALPHA] THEN
  SRW_TAC [][SUB_THM] THEN PROVE_TAC [grandbeta_rules]);

(* property 1 on p37, and Barendregt's lemma 3.2.4 *)
val grandbeta_subst = store_thm(
  "grandbeta_subst",
  ``!M N M' N' x. grandbeta M M' /\ grandbeta N N' ==>
                  grandbeta ([N/x]M) ([N'/x]M')``,
  Q_TAC SUFF_TAC
        `!M M'. grandbeta M M' ==>
                !N N' x. grandbeta N N' ==>
                         grandbeta ([N/x] M) ([N'/x]M')` THEN1
        METIS_TAC [] THEN
  HO_MATCH_MP_TAC grandbeta_ind THEN REPEAT CONJ_TAC THENL [
    METIS_TAC [grandbeta_cosubstitutive],
    REPEAT STRIP_TAC THEN
    Q_TAC (NEW_TAC "z")
          `{x;x'} UNION FV N UNION FV M UNION FV N' UNION FV M'` THEN
    `(LAM x M = LAM z (swap z x M)) /\ (LAM x M' = LAM z (swap z x M'))`
        by SRW_TAC [][swap_ALPHA] THEN
    SRW_TAC [][SUB_THM, swap_subst_out] THEN
    MATCH_MP_TAC (List.nth(CONJUNCTS grandbeta_rules, 1)) THEN
    SRW_TAC [][],
    SRW_TAC [][SUB_THM] THEN METIS_TAC [grandbeta_rules],
    Q_TAC SUFF_TAC
          `!M M' N N' P x.
              (!P P' v. grandbeta P P' ==> grandbeta ([P/v]M) ([P'/v]M')) /\
              (!P P' v. grandbeta P P' ==> grandbeta ([P/v]N) ([P'/v]N')) ==>
              !P P' v.
                 grandbeta P P' ==>
                 grandbeta ([P/v] (LAM x M @@ N)) ([P'/v] ([N'/x] M'))` THEN1
          METIS_TAC [] THEN
    REPEAT STRIP_TAC THEN
    Q_TAC (NEW_TAC "z") `{x;v} UNION FV (M @@ M' @@ N @@ N' @@ P @@ P')` THEN
    FULL_SIMP_TAC (srw_ss()) [] THEN
    `LAM x M = LAM z (swap z x M)` by SRW_TAC [][swap_ALPHA] THEN
    ASM_SIMP_TAC (srw_ss()) [SUB_THM] THEN
    `grandbeta ([P/v] (swap z x M)) ([P'/v] (swap z x M'))`
       by SRW_TAC [][swap_subst_out] THEN
    `grandbeta ([P/v] N) ([P'/v] N')` by SRW_TAC [][] THEN
    Q_TAC SUFF_TAC `[P'/v] ([N'/x] M') =
                    [[P'/v] N' / z] ([P'/v] (swap z x M'))`
          THEN1 METIS_TAC [grandbeta_rules] THEN
    SRW_TAC [][GSYM fresh_var_swap, GSYM GENERAL_SUB_COMMUTE]
  ]);

val strong_grandbeta_ind =
    IndDefRules.derive_strong_induction (CONJUNCTS grandbeta_rules,
                                         grandbeta_ind)

val lemma3_16 = store_thm( (* p. 37 *)
  "lemma3_16",
  ``diamond_property grandbeta``,
  Q_TAC SUFF_TAC `!M M1. grandbeta M M1 ==>
                         !M2. grandbeta M M2 ==>
                              ?M3. grandbeta M1 M3 /\ grandbeta M2 M3` THEN1
    PROVE_TAC [diamond_property_def] THEN
  HO_MATCH_MP_TAC strong_grandbeta_ind THEN REPEAT CONJ_TAC THENL [
    (* reflexive case *)
    PROVE_TAC [grandbeta_rules],
    (* lambda case *)
    MAP_EVERY Q.X_GEN_TAC [`M`,`M1`, `x`] THEN REPEAT STRIP_TAC THEN
    `?P. (M2 = LAM x P) /\ grandbeta M P` by PROVE_TAC [abs_grandbeta] THEN
    SRW_TAC [][] THEN PROVE_TAC [grandbeta_rules],
    (* app case *)
    MAP_EVERY Q.X_GEN_TAC [`f`,`x`,`g`,`y`] THEN STRIP_TAC THEN
    Q.X_GEN_TAC `fx'` THEN STRIP_TAC THEN
    `(?f' x'. (fx' = f' @@ x') /\ grandbeta f f' /\ grandbeta x x') \/
     (?v P P' x'. (f = LAM v P) /\ grandbeta P P' /\ grandbeta x x' /\
                  (fx' = [x'/v]P'))` by
        (FULL_SIMP_TAC (srw_ss()) [app_grandbeta] THEN PROVE_TAC [])
    THENL [
      PROVE_TAC [grandbeta_rules],
      `?P2. (g = LAM v P2) /\ grandbeta P P2` by
          PROVE_TAC [abs_grandbeta] THEN
      SRW_TAC [][] THEN
      `?ff. grandbeta (LAM v P2) ff /\ grandbeta (LAM v P') ff` by
         PROVE_TAC [grandbeta_rules] THEN
      `?xx. grandbeta y xx /\ grandbeta x' xx` by PROVE_TAC [] THEN
      `?PP. grandbeta P' PP /\ (ff = LAM v PP)` by
         PROVE_TAC [abs_grandbeta] THEN
      SRW_TAC [][] THEN
      `grandbeta P2 PP` by PROVE_TAC [abs_grandbeta, LAM_VAR_INJECTIVE] THEN
      PROVE_TAC [grandbeta_rules, grandbeta_subst]
    ],
    (* lambda case *)
    MAP_EVERY Q.X_GEN_TAC [`M`, `N`, `M'`, `N'`, `x`] THEN STRIP_TAC THEN
    Q.X_GEN_TAC `M2` THEN STRIP_TAC THEN
    `(?M1 N1. (M2 = M1 @@ N1) /\ grandbeta (LAM x M) M1 /\ grandbeta N N1) \/
     (?y P P2 N2. (LAM x M = LAM y P) /\ grandbeta P P2 /\ grandbeta N N2 /\
                  (M2 = [N2/y]P2))` by
       (FULL_SIMP_TAC (srw_ss()) [app_grandbeta] THEN PROVE_TAC [])
    THENL [
      `?P1. (M1 = LAM x P1) /\ grandbeta M P1` by
         PROVE_TAC [abs_grandbeta] THEN
      SRW_TAC [][] THEN
      `?Mfin. grandbeta M' Mfin /\ grandbeta P1 Mfin` by PROVE_TAC [] THEN
      `?Nfin. grandbeta N' Nfin /\ grandbeta N1 Nfin` by PROVE_TAC [] THEN
      PROVE_TAC [grandbeta_rules, grandbeta_subst],
      Cases_on `x = y` THENL [
        FULL_SIMP_TAC (srw_ss()) [LAM_VAR_INJECTIVE] THEN SRW_TAC [][] THEN
        `?Mfin. grandbeta M' Mfin /\ grandbeta P2 Mfin` by PROVE_TAC [] THEN
        `?Nfin. grandbeta N' Nfin /\ grandbeta N2 Nfin` by PROVE_TAC [] THEN
        PROVE_TAC [grandbeta_subst],
        `~(x IN FV P) /\ ~(y IN FV M)` by PROVE_TAC [LAM_INJ_ALPHA_FV] THEN
        `M = [VAR x/y] P` by PROVE_TAC [INJECTIVITY_LEMMA1] THEN
        `grandbeta M ([VAR x/y]P2)` by PROVE_TAC [grandbeta_subst,
                                                  grandbeta_rules] THEN
        `?Mfin. grandbeta M' Mfin /\ grandbeta ([VAR x/y]P2) Mfin` by
           PROVE_TAC [] THEN
        `~(x IN FV P2)` by PROVE_TAC [grandbeta_FV,
                                      pred_setTheory.SUBSET_DEF] THEN
        `grandbeta ([VAR y/x]([VAR x/y]P2)) ([VAR y/x] Mfin)` by
           PROVE_TAC [grandbeta_subst, grandbeta_rules] THEN
        `[VAR y/x]([VAR x/y] P2) = P2` by SRW_TAC [][lemma15a, lemma14a] THEN
        POP_ASSUM SUBST_ALL_TAC THEN SRW_TAC [][] THEN
        `?Nfin. grandbeta N' Nfin /\ grandbeta N2 Nfin` by PROVE_TAC [] THEN
        `grandbeta ([N'/x]M') ([Nfin/x]Mfin)` by
           PROVE_TAC [grandbeta_subst] THEN
        Q.EXISTS_TAC `[Nfin/x]Mfin` THEN SRW_TAC [][] THEN
        `~(y IN FV ([VAR x/y]P2))` by
           PROVE_TAC [pred_setTheory.SUBSET_DEF, grandbeta_FV] THEN
        `~(y IN FV Mfin)` by
           PROVE_TAC [pred_setTheory.SUBSET_DEF, grandbeta_FV] THEN
        `grandbeta ([N2/y]P2) ([Nfin/y]([VAR y/x]Mfin))` by
           PROVE_TAC [grandbeta_subst, grandbeta_rules] THEN
        POP_ASSUM MP_TAC THEN SRW_TAC [][lemma15a]
      ]
    ]
  ]);

val theorem3_17 = store_thm(
  "theorem3_17",
  ``TC grandbeta = reduction beta``,
  Q_TAC SUFF_TAC
    `(!M N:'a nc. TC grandbeta M N ==> reduction beta M N) /\
     (!M N:'a nc. RTC (compat_closure beta) M N ==> TC grandbeta M N)`
    THEN1 SRW_TAC [] [reduction_def, FUN_EQ_THM, EQ_IMP_THM] THEN
  CONJ_TAC THENL [
    Q_TAC SUFF_TAC `!M N. grandbeta M N ==> reduction beta M N`
      THEN1 (REWRITE_TAC [reduction_def] THEN
             PROVE_TAC [relationTheory.TC_IDEM, relationTheory.TC_RC_EQNS,
                        relationTheory.TC_MONOTONE]) THEN
    HO_MATCH_MP_TAC grandbeta_ind THEN PROVE_TAC [reduction_rules, beta_def],

    Q_TAC SUFF_TAC `!M N. RC (compat_closure beta) M N ==> grandbeta M N`
      THEN1 PROVE_TAC [relationTheory.TC_MONOTONE,
                       relationTheory.TC_RC_EQNS] THEN
    Q_TAC SUFF_TAC `!M N. compat_closure beta M N ==> grandbeta M N`
      THEN1 PROVE_TAC [relationTheory.RC_DEF, grandbeta_rules] THEN
    PROVE_TAC [exercise3_3_1]
  ]);

val beta_CR = store_thm(
  "beta_CR",
  ``CR beta``,
  PROVE_TAC [CR_def, lemma3_16, theorem3_17, diamond_TC]);

val lameq_betaconversion = store_thm(
  "lameq_betaconversion",
  ``!M N. M == N = conversion beta M N``,
  SIMP_TAC (srw_ss()) [EQ_IMP_THM, FORALL_AND_THM] THEN CONJ_TAC THENL [
    HO_MATCH_MP_TAC lam_eq_indn THEN REPEAT STRIP_TAC THENL [
      Q_TAC SUFF_TAC `beta (LAM x M @@ N) ([N/x] M)` THEN1
        PROVE_TAC [conversion_rules] THEN
      SRW_TAC [][beta_def] THEN PROVE_TAC [],
      PROVE_TAC [conversion_rules],
      PROVE_TAC [conversion_rules],
      PROVE_TAC [conversion_rules],
      PROVE_TAC [conversion_compatible, compatible_def, rightctxt,
                 rightctxt_thm],
      PROVE_TAC [conversion_compatible, compatible_def, leftctxt],
      PROVE_TAC [conversion_compatible, compatible_def, absctxt]
    ],
    SIMP_TAC (srw_ss()) [conversion_def] THEN
    HO_MATCH_MP_TAC equiv_closure_ind THEN REPEAT CONJ_TAC THEN1
      (HO_MATCH_MP_TAC compat_closure_ind THEN SRW_TAC [][beta_def] THEN
       PROVE_TAC [lam_eq_rules]) THEN
    PROVE_TAC [lam_eq_rules]
  ]);

val prop3_18 = save_thm("prop3_18", lameq_betaconversion);

val lameq_consistent = store_thm(
  "lameq_consistent",
  ``consistent $==``,
  SRW_TAC [][consistent_def] THEN
  MAP_EVERY Q.EXISTS_TAC [`S`,`K`] THEN STRIP_TAC THEN
  `conversion beta S K` by PROVE_TAC [prop3_18] THEN
  `?Z. reduction beta S Z /\ reduction beta K Z` by
     PROVE_TAC [theorem3_13, beta_CR] THEN
  `normal_form beta S` by PROVE_TAC [S_beta_normal, beta_normal_form_bnf] THEN
  `normal_form beta K` by PROVE_TAC [K_beta_normal, beta_normal_form_bnf] THEN
  `S = K` by PROVE_TAC [corollary3_2_1] THEN
  FULL_SIMP_TAC (srw_ss()) [S_def, K_def]);

val weak_diamond_def =  (* definition 3.19, p39 *)
    Define`weak_diamond R = !M M1 M2. R M M1 /\ R M M2 ==>
                                      ?M3. RTC R M1 M3 /\ RTC R M2 M3`;

val WCR_def = (* definition 3.20, p39 *)
    Define`WCR R = weak_diamond (compat_closure R)`;

val SN_def = Define`SN R = WF (inv (compat_closure R))`;

val EXTEND_RTC_TC = store_thm(
  "EXTEND_RTC_TC",
  ``!R x y z. R x y /\ RTC R y z ==> TC R x z``,
  GEN_TAC THEN
  Q_TAC SUFF_TAC `!y z. RTC R y z ==> !x. R x y ==> TC R x z` THEN1
        PROVE_TAC [] THEN
  HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN
  PROVE_TAC [relationTheory.TC_RULES]);

val newmans_lemma = store_thm( (* lemma3_22, p39 *)
  "newmans_lemma",
  ``!R. SN R /\ WCR R ==> CR R``,
  REPEAT STRIP_TAC THEN
  `WF (TC (inv (compat_closure R)))` by
       PROVE_TAC [relationTheory.WF_TC, SN_def] THEN
  SIMP_TAC (srw_ss()) [CR_def, diamond_property_def] THEN
  POP_ASSUM (HO_MATCH_MP_TAC o MATCH_MP relationTheory.WF_INDUCTION_THM) THEN
  SRW_TAC [][relationTheory.inv_DEF, relationTheory.inv_MOVES_OUT] THEN
  `(M1 = M) \/ (?M1'. compat_closure R M M1' /\ reduction R M1' M1)` by
     PROVE_TAC [reduction_def, relationTheory.RTC_CASES1]
  THENL [
    POP_ASSUM SUBST_ALL_TAC THEN PROVE_TAC [reduction_rules],
    ALL_TAC
  ] THEN
  `(M2 = M) \/ (?M2'. compat_closure R M M2' /\ reduction R M2' M2)` by
     PROVE_TAC [reduction_def, relationTheory.RTC_CASES1]
  THENL [
    POP_ASSUM SUBST_ALL_TAC THEN PROVE_TAC [reduction_rules],
    ALL_TAC
  ] THEN
  `?M0. reduction R M1' M0 /\ reduction R M2' M0` by
    (FULL_SIMP_TAC (srw_ss()) [reduction_def, WCR_def, weak_diamond_def] THEN
     PROVE_TAC []) THEN
  `TC (compat_closure R) M M1' /\ TC (compat_closure R) M M2'` by
    PROVE_TAC [relationTheory.TC_RULES] THEN
  `?M10. reduction R M1 M10 /\ reduction R M0 M10` by PROVE_TAC [] THEN
  `?M20. reduction R M2 M20 /\ reduction R M0 M20` by PROVE_TAC [] THEN
  `TC (compat_closure R) M M0` by PROVE_TAC [EXTEND_RTC_TC, reduction_def] THEN
  `?M3. reduction R M10 M3 /\ reduction R M20 M3` by PROVE_TAC [] THEN
  PROVE_TAC [reduction_rules]);

val commute_def =  (* p43 *)
    Define`commute R1 R2 = !x x1 x2. R1 x x1 /\ R2 x x2 ==>
                                     ?x3. R2 x1 x3 /\ R1 x2 x3`;

val commute_COMM = store_thm(
  "commute_COMM",
  ``commute R1 R2 = commute R2 R1``,
  PROVE_TAC [commute_def]);

val diamond_RC = store_thm(
  "diamond_RC",
  ``!R. diamond_property R ==> diamond_property (RC R)``,
  SRW_TAC [][relationTheory.RC_DEF, diamond_property_def, RIGHT_AND_OVER_OR,
             LEFT_AND_OVER_OR, EXISTS_OR_THM] THEN
  PROVE_TAC [diamond_property_def]);

val diamond_RTC = store_thm(
  "diamond_RTC",
  ``!R. diamond_property R ==> diamond_property (RTC R)``,
  PROVE_TAC [diamond_TC, diamond_RC, relationTheory.TC_RC_EQNS]);

fun CONJ1_TAC f (asl, w) = let
  val (c1, c2) = dest_conj w
in
  SUBGOAL_THEN c1 (fn th => CONJ_TAC THENL [ACCEPT_TAC th, ASSUME_TAC (f th)])
end (asl, w)

val hr_lemma0 = prove(
  ``!R1 R2. diamond_property R1 /\ diamond_property R2 /\ commute R1 R2 ==>
            diamond_property (RTC (R1 RUNION R2))``,
  REPEAT STRIP_TAC THEN
  Q_TAC SUFF_TAC `diamond_property (R1 RUNION R2)` THEN1
        PROVE_TAC [diamond_RTC] THEN
  FULL_SIMP_TAC (srw_ss()) [diamond_property_def, commute_def,
                            relationTheory.RUNION] THEN
  PROVE_TAC []);

val RUNION_RTC_MONOTONE = store_thm(
  "RUNION_RTC_MONOTONE",
  ``!R1 x y. RTC R1 x y ==> !R2. RTC (R1 RUNION R2) x y``,
  GEN_TAC THEN HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN
  PROVE_TAC [relationTheory.RTC_RULES, relationTheory.RUNION]);

val RUNION_COMM = relationTheory.RUNION_COMM

val RTC_OUT = store_thm(
  "RTC_OUT",
  ``!R1 R2. RTC (RTC R1 RUNION RTC R2) = RTC (R1 RUNION R2)``,
  REPEAT GEN_TAC THEN
  Q_TAC SUFF_TAC
    `(!x y. RTC (RTC R1 RUNION RTC R2) x y ==> RTC (R1 RUNION R2) x y) /\
     (!x y. RTC (R1 RUNION R2) x y ==> RTC (RTC R1 RUNION RTC R2) x y)` THEN1
    (SIMP_TAC (srw_ss()) [FUN_EQ_THM, EQ_IMP_THM, FORALL_AND_THM] THEN
     PROVE_TAC []) THEN CONJ_TAC
  THEN HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THENL [
    CONJ_TAC THENL [
      PROVE_TAC [relationTheory.RTC_RULES],
      MAP_EVERY Q.X_GEN_TAC [`x`,`y`,`z`] THEN REPEAT STRIP_TAC THEN
      `RTC R1 x y \/ RTC R2 x y` by PROVE_TAC [relationTheory.RUNION] THEN
      PROVE_TAC [RUNION_RTC_MONOTONE, relationTheory.RTC_RTC, RUNION_COMM]
    ],
    CONJ_TAC THENL [
      PROVE_TAC [relationTheory.RTC_RULES],
      MAP_EVERY Q.X_GEN_TAC [`x`,`y`,`z`] THEN REPEAT STRIP_TAC THEN
      `R1 x y \/ R2 x y` by PROVE_TAC [relationTheory.RUNION] THEN
      PROVE_TAC [relationTheory.RTC_RULES, relationTheory.RUNION]
    ]
  ]);


val CC_RUNION_MONOTONE = store_thm(
  "CC_RUNION_MONOTONE",
  ``!R1 x y. compat_closure R1 x y ==> compat_closure (R1 RUNION R2) x y``,
  GEN_TAC THEN HO_MATCH_MP_TAC compat_closure_ind THEN
  PROVE_TAC [compat_closure_rules, relationTheory.RUNION]);

val CC_RUNION_DISTRIB = store_thm(
  "CC_RUNION_DISTRIB",
  ``!R1 R2. compat_closure (R1 RUNION R2) =
            compat_closure R1 RUNION compat_closure R2``,
  REPEAT GEN_TAC THEN
  Q_TAC SUFF_TAC
     `(!x y. compat_closure (R1 RUNION R2) x y ==>
             (compat_closure R1 RUNION compat_closure R2) x y) /\
      (!x y. (compat_closure R1 RUNION compat_closure R2) x y ==>
             compat_closure (R1 RUNION R2) x y)` THEN1
     SIMP_TAC (srw_ss()) [FUN_EQ_THM, EQ_IMP_THM, FORALL_AND_THM] THEN
  CONJ_TAC THENL [
    HO_MATCH_MP_TAC compat_closure_ind THEN
    PROVE_TAC [compat_closure_rules, relationTheory.RUNION],
    SRW_TAC [][relationTheory.RUNION] THEN
    PROVE_TAC [RUNION_COMM, CC_RUNION_MONOTONE]
  ]);

val hindley_rosen_lemma = store_thm( (* p43 *)
  "hindley_rosen_lemma",
  ``(!R1 R2. diamond_property R1 /\ diamond_property R2 /\ commute R1 R2 ==>
             diamond_property (RTC (R1 RUNION R2))) /\
    (!R1 R2. CR R1 /\ CR R2 /\ commute (reduction R1) (reduction R2) ==>
             CR (R1 RUNION R2))``,
  CONJ_TAC THENL [
    MATCH_ACCEPT_TAC hr_lemma0,
    SRW_TAC [][CR_def, reduction_def] THEN
    `diamond_property (RTC (RTC (compat_closure R1) RUNION
                            RTC (compat_closure R2)))`
        by PROVE_TAC [hr_lemma0] THEN
    FULL_SIMP_TAC (srw_ss()) [RTC_OUT, CC_RUNION_DISTRIB]
  ]);

val eta_def =
    Define`eta M N = ?v. (M = LAM v (N @@ VAR v)) /\ ~(v IN FV N)`;

val eta_normal_form_enf = store_thm(
  "eta_normal_form_enf",
  ``normal_form eta = enf``,
  Q_TAC SUFF_TAC `(!x:'a nc. ~enf x ==> can_reduce eta x) /\
                  (!x:'a nc. can_reduce eta x ==> ~enf x)` THEN1
    (SIMP_TAC (srw_ss())[normal_form_def, FUN_EQ_THM, EQ_IMP_THM,
                         FORALL_AND_THM] THEN PROVE_TAC []) THEN
  CONJ_TAC THENL [
    HO_MATCH_MP_TAC nc_INDUCTION THEN
    SRW_TAC [][] THENL [
      PROVE_TAC [can_reduce_rules],
      PROVE_TAC [can_reduce_rules],
      PROVE_TAC [can_reduce_rules, lemma14a],
      Q_TAC SUFF_TAC `?u. eta (LAM x x') u` THEN1
            PROVE_TAC [can_reduce_rules, redex_def] THEN
      FULL_SIMP_TAC (srw_ss()) [is_comb_APP_EXISTS, eta_def] THEN
      SRW_TAC [][] THEN
      FULL_SIMP_TAC (srw_ss()) [rand_thm, rator_thm] THEN PROVE_TAC []
    ],
    HO_MATCH_MP_TAC can_reduce_ind THEN
    SRW_TAC [][redex_def, eta_def] THEN
    SRW_TAC [][]
  ]);

val no_eta_thm = store_thm(
  "no_eta_thm",
  ``(!s t. ~(eta (VAR s) t)) /\
    (!k t. ~(eta (CON k) t)) /\
    (!t u v. ~(eta (t @@ u) v))``,
  SRW_TAC [][eta_def]);

val cc_eta_thm = store_thm(
  "cc_eta_thm",
  ``(!s t. compat_closure eta (VAR s) t = F) /\
    (!k t. compat_closure eta (CON k) t = F) /\
    (!t u v. compat_closure eta (t @@ u) v =
             is_comb v /\ compat_closure eta t (rator v) /\ (u = rand v) \/
             is_comb v /\ compat_closure eta u (rand v) /\ (t = rator v))``,
  CONV_TAC (EVERY_CONJ_CONV
              (STRIP_QUANT_CONV
                 (LAND_CONV (ONCE_REWRITE_CONV [compat_closure_cases])))) THEN
  SIMP_TAC (srw_ss()) [no_eta_thm, EQ_IMP_THM, DISJ_IMP_THM,
                       GSYM LEFT_FORALL_IMP_THM, RIGHT_AND_OVER_OR,
                       LEFT_AND_OVER_OR, FORALL_AND_THM,
                       is_comb_APP_EXISTS, GSYM LEFT_EXISTS_AND_THM]);

val eta_substitutive = store_thm(
  "eta_substitutive",
  ``substitutive eta``,
  SRW_TAC [][substitutive_def, eta_def] THEN
  Q_TAC (NEW_TAC "z") `{v;v'} UNION FV M' UNION FV N` THEN
  `LAM v (M' @@ VAR v) = LAM z ([VAR z/v] (M' @@ VAR v))`
     by SRW_TAC [][SIMPLE_ALPHA] THEN
  ` _ = LAM z ([VAR z/v] M' @@ VAR z)` by SRW_TAC [][SUB_THM] THEN
  ASM_SIMP_TAC (srw_ss()) [SUB_THM, lemma14b] THEN
  Q.EXISTS_TAC `z` THEN SRW_TAC [][FV_SUB]);

val cc_eta_subst = store_thm(
  "cc_eta_subst",
  ``!M N. compat_closure eta M N ==>
          !P v. compat_closure eta ([P/v] M) ([P/v] N)``,
  METIS_TAC [eta_substitutive, compat_closure_substitutive, substitutive_def]);

val eta_deterministic = store_thm(
  "eta_deterministic",
  ``!M N1 N2. eta M N1 /\ eta M N2 ==> (N1 = N2)``,
  SRW_TAC [][eta_def] THEN
  IMP_RES_THEN MP_TAC INJECTIVITY_LEMMA1 THEN
  ASM_SIMP_TAC (srw_ss()) [SUB_THM, lemma14b]);

val cc_eta_FV_SUBSET = store_thm(
  "cc_eta_FV_SUBSET",
  ``!M N. compat_closure eta M N ==> FV N SUBSET FV M``,
  HO_MATCH_MP_TAC compat_closure_ind THEN
  SIMP_TAC (srw_ss()) [pred_setTheory.SUBSET_DEF] THEN
  Q_TAC SUFF_TAC `!M N. eta M N ==> !s. s IN FV N ==> s IN FV M` THEN1
        PROVE_TAC [] THEN
  SIMP_TAC (srw_ss()) [eta_def, GSYM LEFT_FORALL_IMP_THM]);

val cc_eta_LAM = store_thm(
  "cc_eta_LAM",
  ``!t v u. compat_closure eta (LAM v t) u =
            (?t'. (u = LAM v t') /\ compat_closure eta t t') \/
            eta (LAM v t) u``,
  REPEAT GEN_TAC THEN
  CONV_TAC (LAND_CONV (ONCE_REWRITE_CONV [compat_closure_cases])) THEN
  EQ_TAC THEN STRIP_TAC THEN FULL_SIMP_TAC (srw_ss()) [] THENL [
    DISJ1_TAC THEN
    `t = [VAR v/v']x` by PROVE_TAC [INJECTIVITY_LEMMA1] THEN
    `compat_closure eta t ([VAR v/v']y)` by PROVE_TAC [cc_eta_subst] THEN
    Cases_on `v = v'` THENL [
      PROVE_TAC [lemma14a],
      `~(v IN FV x)` by PROVE_TAC [LAM_INJ_ALPHA_FV] THEN
      `~(v IN FV y)` by PROVE_TAC [cc_eta_FV_SUBSET,
                                   pred_setTheory.SUBSET_DEF] THEN
      PROVE_TAC [SIMPLE_ALPHA]
    ],
    PROVE_TAC []
  ]);

val eta_LAM = store_thm(
  "eta_LAM",
  ``!v t u. eta (LAM v t) u =
            is_comb t /\ ~(v IN FV (rator t)) /\ (rand t = VAR v) /\
            (u = rator t)``,
  SRW_TAC [][eta_def] THEN EQ_TAC THEN SRW_TAC [][] THEN
  TRY (IMP_RES_THEN MP_TAC INJECTIVITY_LEMMA1) THEN
  FULL_SIMP_TAC (srw_ss()) [SUB_THM, rator_thm, lemma14b] THENL [
    DISCH_THEN SUBST_ALL_TAC THEN
    Cases_on `v = v'` THEN1 PROVE_TAC [] THEN
    PROVE_TAC [LAM_INJ_ALPHA_FV, FV_THM, pred_setTheory.IN_UNION],
    PROVE_TAC [is_comb_rator_rand]
  ]);

val CR_eta_lemma = prove(
  ``!M M1 M2. eta M M1 /\ compat_closure eta M M2 /\ ~(M1 = M2) ==>
              ?M3. compat_closure eta M1 M3 /\ compat_closure eta M2 M3``,
  REPEAT STRIP_TAC THEN
  `?v. (M = LAM v (M1 @@ VAR v)) /\ ~(v IN FV M1)` by PROVE_TAC [eta_def] THEN
  `?w c d. (M = LAM w c) /\ (M2 = LAM w d) /\
           compat_closure eta c d` by
         (RULE_ASSUM_TAC (ONCE_REWRITE_RULE [compat_closure_cases]) THEN
          FULL_SIMP_TAC (srw_ss()) [] THEN
          PROVE_TAC [eta_deterministic]) THEN
  `c = [VAR w/v](M1 @@ VAR v)` by PROVE_TAC [INJECTIVITY_LEMMA1] THEN
  `c = M1 @@ VAR w` by SRW_TAC [][SUB_THM, SUB_VAR, lemma14b] THEN
  `?c'. compat_closure eta M1 c' /\ (d = c' @@ VAR w)` by
         (FULL_SIMP_TAC (srw_ss()) [SUB_THM, no_eta_thm, cc_eta_thm] THEN
          PROVE_TAC [is_comb_rator_rand]) THEN
  `~(w IN FV M1)` by
         (Q_TAC SUFF_TAC `~(v = w) ==> ~(w IN FV (M1 @@ VAR v))` THEN1
                (SRW_TAC [][SUB_THM] THEN PROVE_TAC []) THEN
          PROVE_TAC [LAM_INJ_ALPHA_FV, FV_THM, pred_setTheory.IN_UNION]) THEN
  `~(w IN FV c')` by PROVE_TAC [cc_eta_FV_SUBSET,
                                pred_setTheory.SUBSET_DEF] THEN
  `eta M2 c'` by (SRW_TAC [][eta_def] THEN PROVE_TAC []) THEN
  PROVE_TAC [compat_closure_rules]);

val cc_strong_ind =
    IndDefRules.derive_strong_induction
    (CONJUNCTS (Q.SPEC `R` compat_closure_rules), compat_closure_ind)

val eta_diamond = prove(
  ``!M M1. compat_closure eta M M1 ==>
           !M2. compat_closure eta M M2 /\ ~(M1 = M2) ==>
                ?M3. compat_closure eta M1 M3 /\
                     compat_closure eta M2 M3``,
  HO_MATCH_MP_TAC cc_strong_ind THEN REPEAT CONJ_TAC THENL [
    PROVE_TAC [CR_eta_lemma],

    Q_TAC SUFF_TAC
          `!M M1 z.
              compat_closure eta M M1 /\
              (!N0. compat_closure eta M N0 /\ ~(M1 = N0) ==>
                    ?N. compat_closure eta M1 N /\ compat_closure eta N0 N) ==>
              !M2. compat_closure eta (z @@ M) M2 /\ ~(z @@ M1 = M2) ==>
                   ?M3. compat_closure eta (z @@ M1) M3 /\
                        compat_closure eta M2 M3` THEN1 PROVE_TAC [] THEN
    REPEAT STRIP_TAC THEN
    `is_comb M2 /\ compat_closure eta z (rator M2) /\ (rand M2 = M) \/
     is_comb M2 /\ compat_closure eta M (rand M2) /\ (rator M2 = z)` by
       FULL_SIMP_TAC (srw_ss()) [cc_eta_thm]
    THENL [
      PROVE_TAC [compat_closure_rules, is_comb_rator_rand],
      `~(rand M2 = M1)` by PROVE_TAC [is_comb_rator_rand] THEN
      `?N. compat_closure eta M1 N /\ compat_closure eta (rand M2) N` by
            PROVE_TAC [] THEN
      Q.EXISTS_TAC `z @@ N` THEN
      `rator M2 @@ rand M2 = M2` by PROVE_TAC [is_comb_rator_rand] THEN
      PROVE_TAC [compat_closure_rules]
    ],

    Q_TAC SUFF_TAC
          `!M M1 z.
              compat_closure eta M M1 /\
              (!N0. compat_closure eta M N0 /\ ~(M1 = N0) ==>
                    ?N. compat_closure eta M1 N /\ compat_closure eta N0 N) ==>
              !M2. compat_closure eta (M @@ z) M2 /\ ~(M1 @@ z = M2) ==>
                   ?M3. compat_closure eta (M1 @@ z) M3 /\
                        compat_closure eta M2 M3` THEN1 PROVE_TAC [] THEN
    REPEAT STRIP_TAC THEN
    `is_comb M2 /\ compat_closure eta z (rand M2) /\ (rator M2 = M) \/
     is_comb M2 /\ compat_closure eta M (rator M2) /\ (rand M2 = z)` by
       FULL_SIMP_TAC (srw_ss()) [cc_eta_thm]
    THENL [
      PROVE_TAC [compat_closure_rules, is_comb_rator_rand],
      `~(M1 = rator M2)` by PROVE_TAC [is_comb_rator_rand] THEN
      `?N. compat_closure eta M1 N /\ compat_closure eta (rator M2) N` by
          PROVE_TAC [] THEN
      `rator M2 @@ rand M2 = M2` by PROVE_TAC [is_comb_rator_rand] THEN
      Q.EXISTS_TAC `N @@ z` THEN
      PROVE_TAC [compat_closure_rules]
    ],

    Q_TAC SUFF_TAC
          `!M M1 v.
              compat_closure eta M M1 /\
              (!N0. compat_closure eta M N0 /\ ~(M1 = N0) ==>
                    ?N. compat_closure eta M1 N /\ compat_closure eta N0 N) ==>
              !M2. compat_closure eta (LAM v M) M2 /\ ~(LAM v M1 = M2) ==>
                   ?M3. compat_closure eta (LAM v M1) M3 /\
                        compat_closure eta M2 M3` THEN1 PROVE_TAC [] THEN
    REPEAT STRIP_TAC THEN
    `eta (LAM v M) M2 \/ ?b. compat_closure eta M b /\ (M2 = LAM v b)` by
       PROVE_TAC [cc_eta_LAM]
    THENL [
      `compat_closure eta (LAM v M) (LAM v M1)` by
         PROVE_TAC [compat_closure_rules] THEN
      PROVE_TAC [CR_eta_lemma],
      `~(M1 = b)` by FULL_SIMP_TAC (srw_ss()) [] THEN
      `?N. compat_closure eta M1 N /\ compat_closure eta b N` by
         PROVE_TAC [] THEN
      Q.EXISTS_TAC `LAM v N` THEN PROVE_TAC [compat_closure_rules]
    ]
  ]);

val eta_CR = store_thm(
  "eta_CR",
  ``CR eta``,
  Q_TAC SUFF_TAC `diamond_property (RC (compat_closure eta))` THEN1
        (SRW_TAC [][CR_def, reduction_def] THEN
         PROVE_TAC [relationTheory.TC_RC_EQNS, diamond_TC]) THEN
  SIMP_TAC (srw_ss()) [diamond_property_def, relationTheory.RC_DEF,
                       RIGHT_AND_OVER_OR, LEFT_AND_OVER_OR, EXISTS_OR_THM,
                       DISJ_IMP_THM, FORALL_AND_THM] THEN
  PROVE_TAC [eta_diamond]);

val wonky_diamond_commutes = store_thm( (* Barendregt, lemma 3.3.6 *)
  "wonky_diamond_commutes",
  ``!R1 R2.
        (!x y z. R1 x y /\ R2 x z ==> ?w. RTC R1 z w /\ RC R2 y w) ==>
        commute (RTC R1) (RTC R2)``,
  REPEAT STRIP_TAC THEN
  `!x y. RTC R1 x y ==> !z. R2 x z ==> ?w. RTC R1 z w /\ RTC R2 y w` by
      (HO_MATCH_MP_TAC relationTheory.RTC_STRONG_INDUCT THEN
       CONJ_TAC THENL [
         PROVE_TAC [relationTheory.RTC_RULES],
         MAP_EVERY Q.X_GEN_TAC [`x`,`y`,`z`] THEN REPEAT STRIP_TAC THEN
         `?w. RC R2 y w /\ RTC R1 z' w` by PROVE_TAC [] THEN
         FULL_SIMP_TAC (srw_ss()) [relationTheory.RC_DEF] THEN
         PROVE_TAC [relationTheory.RTC_RTC, relationTheory.RTC_RULES]
       ]) THEN
  Q_TAC SUFF_TAC
        `!x y. RTC R2 x y ==> !z. RTC R1 x z ==>
                                  ?w. RTC R2 z w /\ RTC R1 y w` THEN1
        (SRW_TAC [][commute_def] THEN PROVE_TAC []) THEN
  HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN
  PROVE_TAC [relationTheory.RTC_RULES, relationTheory.RTC_RTC]);

val eta_cosubstitutive = store_thm(
  "eta_cosubstitutive",
  ``!P M N x. compat_closure eta M N ==> reduction eta ([M/x] P) ([N/x] P)``,
  HO_MATCH_MP_TAC nc_INDUCTION THEN REPEAT CONJ_TAC THENL [
    (* con case *) SRW_TAC [][SUB_THM, reduction_rules],
    (* var case *) SRW_TAC [][SUB_VAR, reduction_rules],
    (* app case *) SRW_TAC [][SUB_THM] THEN PROVE_TAC [reduction_rules],
    REPEAT STRIP_TAC THEN
    Q_TAC (NEW_TAC "z") `FV P UNION FV N UNION FV M UNION {x;x'}` THEN
    `LAM x P = LAM z ([VAR z/x] P)` by SRW_TAC [][SIMPLE_ALPHA] THEN
    SRW_TAC [][SUB_THM] THEN
    PROVE_TAC [reduction_rules]
  ]);

val eta_beta_commute = store_thm(
  "eta_beta_commute",
  ``commute (reduction eta) (reduction beta)``,
  SIMP_TAC (srw_ss()) [reduction_def] THEN
  MATCH_MP_TAC wonky_diamond_commutes THEN
  Q_TAC SUFF_TAC
        `!M N. compat_closure eta M N ==>
               !P. compat_closure beta M P ==>
                   ?Q. RTC (compat_closure eta) P Q /\
                       RC (compat_closure beta) N Q` THEN1 PROVE_TAC [] THEN
  HO_MATCH_MP_TAC cc_strong_ind THEN REPEAT CONJ_TAC THENL [
    MAP_EVERY Q.X_GEN_TAC [`M`, `N`] THEN
    REPEAT STRIP_TAC THEN
    `?v. (M = LAM v (N @@ VAR v)) /\ ~(v IN FV N)` by PROVE_TAC [eta_def] THEN
    `?P0. (P = LAM v P0) /\ compat_closure beta (N @@ VAR v) P0` by
          PROVE_TAC [last (CONJUNCTS cc_beta_thm)] THEN
    `(?u body. (N = LAM u body) /\ (P0 = [VAR v/u]body)) \/
     is_comb P0 /\ compat_closure beta N (rator P0) /\ (rand P0 = VAR v)` by
        (FULL_SIMP_TAC (srw_ss()) [cc_beta_thm] THEN PROVE_TAC [])
    THENL [
      SRW_TAC [][relationTheory.RC_DEF] THEN Q.EXISTS_TAC `LAM u body` THEN
      PROVE_TAC [ALPHA, relationTheory.RTC_RULES],
      Q.EXISTS_TAC `rator P0` THEN
      `~(v IN FV (rator P0))` by PROVE_TAC [pred_setTheory.SUBSET_DEF,
                                            cc_beta_FV_SUBSET] THEN
      `eta P (rator P0)` by (SRW_TAC [][eta_def] THEN
                             PROVE_TAC [is_comb_rator_rand]) THEN
      SRW_TAC [][relationTheory.RC_DEF] THEN
      PROVE_TAC [relationTheory.RTC_RULES, compat_closure_rules]
    ],

    REPEAT STRIP_TAC THEN FULL_SIMP_TAC (srw_ss()) [cc_beta_thm] THENL [
      Q.EXISTS_TAC `[N/v]M0` THEN
      `beta (LAM v M0 @@ N) ([N/v]M0)` by PROVE_TAC [beta_def] THEN
      SRW_TAC [][relationTheory.RC_DEF] THENL [
        PROVE_TAC [eta_cosubstitutive, reduction_def],
        PROVE_TAC [compat_closure_rules]
      ],
      Q.EXISTS_TAC `rator P @@ N` THEN SRW_TAC [][relationTheory.RC_DEF]
      THENL [
        PROVE_TAC [relationTheory.RTC_RULES, is_comb_rator_rand,
                   compat_closure_rules],
        PROVE_TAC [compat_closure_rules]
      ],
      `?Q0. RTC (compat_closure eta) (rand P) Q0 /\
            RC (compat_closure beta) N Q0` by PROVE_TAC [] THEN
      `reduction eta (rand P) Q0` by SRW_TAC [][reduction_def] THEN
      Q.EXISTS_TAC `z @@ Q0` THEN
      `RC (compat_closure beta) (z @@ N) (z @@ Q0)` by
          (FULL_SIMP_TAC (srw_ss())[relationTheory.RC_DEF] THEN
           PROVE_TAC [compat_closure_rules]) THEN
      Q_TAC SUFF_TAC `reduction eta P (z @@ Q0)` THEN1
            SRW_TAC [][reduction_def] THEN
      PROVE_TAC [is_comb_rator_rand, reduction_rules]
    ],

    Q_TAC SUFF_TAC
          `!M N arg.
              compat_closure eta M N /\
              (!P. compat_closure beta M P ==>
                   ?Q.  RTC (compat_closure eta) P Q /\
                        RC (compat_closure beta) N Q) ==>
              !P. compat_closure beta (M @@ arg) P ==>
                  ?Q.  RTC (compat_closure eta) P Q /\
                       RC (compat_closure beta) (N @@ arg) Q` THEN1
          PROVE_TAC [] THEN
    REPEAT STRIP_TAC THEN
    `(?v M0. (M = LAM v M0) /\ (P = [arg/v] M0)) \/
     (is_comb P /\ compat_closure beta M (rator P) /\ (rand P = arg)) \/
     (is_comb P /\ compat_closure beta arg (rand P) /\ (rator P = M))` by
        (FULL_SIMP_TAC (srw_ss()) [cc_beta_thm] THEN PROVE_TAC [])
    THENL [
      `(?N0. (N = LAM v N0) /\ compat_closure eta M0 N0) \/ eta (LAM v M0) N`
      by PROVE_TAC [cc_eta_LAM] THENL [
         Q.EXISTS_TAC `[arg/v]N0` THEN
         `beta (N @@ arg) ([arg/v] N0)` by
            (SRW_TAC [][beta_def] THEN PROVE_TAC []) THEN
         PROVE_TAC [cc_eta_subst, relationTheory.RTC_RULES,
                    relationTheory.RC_DEF, compat_closure_rules],
         `(N = rator M0) /\ ~(v IN FV (rator M0)) /\ (rand M0 = VAR v) /\
          is_comb M0` by
            PROVE_TAC [eta_LAM] THEN
         Q.EXISTS_TAC `P` THEN SRW_TAC [][relationTheory.RTC_RULES] THEN
         `M0 = (rator M0) @@ (rand M0)` by PROVE_TAC [is_comb_rator_rand] THEN
         POP_ASSUM SUBST_ALL_TAC THEN
         FULL_SIMP_TAC (srw_ss()) [rator_thm, rand_thm, relationTheory.RC_DEF,
                                   SUB_THM, lemma14b]
      ],
      `?Q0. RTC (compat_closure eta) (rator P) Q0 /\
            RC (compat_closure beta) N Q0` by PROVE_TAC [] THEN
      `reduction eta (rator P) Q0` by SRW_TAC [][reduction_def] THEN
      Q.EXISTS_TAC `Q0 @@ arg` THEN
      `RC (compat_closure beta) (N @@ arg) (Q0 @@ arg)` by
          (FULL_SIMP_TAC (srw_ss()) [relationTheory.RC_DEF] THEN
           PROVE_TAC [compat_closure_rules]) THEN
      Q_TAC SUFF_TAC `reduction eta P (Q0 @@ arg)` THEN1
            SRW_TAC [][reduction_def] THEN
      PROVE_TAC [is_comb_rator_rand, reduction_rules],
      Q.EXISTS_TAC `N @@ (rand P)` THEN
      `compat_closure beta (N @@ arg) (N @@ rand P)`
         by PROVE_TAC [compat_closure_rules] THEN
      SRW_TAC [][relationTheory.RC_DEF] THEN
      PROVE_TAC [relationTheory.RTC_RULES, compat_closure_rules,
                 is_comb_rator_rand]
    ],

    REPEAT STRIP_TAC THEN
    FULL_SIMP_TAC (srw_ss()) [cc_beta_thm] THEN
    `?Q0. RTC (compat_closure eta) N0 Q0 /\ RC (compat_closure beta) N Q0` by
         PROVE_TAC [] THEN
    `RC (compat_closure beta) (LAM v N) (LAM v Q0)` by
        (FULL_SIMP_TAC (srw_ss()) [relationTheory.RC_DEF] THEN
         PROVE_TAC [compat_closure_rules]) THEN
    `RTC (compat_closure eta) (LAM v N0) (LAM v Q0)` by
       PROVE_TAC [reduction_rules, reduction_def] THEN
    PROVE_TAC []
  ]);

val beta_eta_CR = store_thm(
  "beta_eta_CR",
  ``CR (beta RUNION eta)``,
  MATCH_MP_TAC (CONJUNCT2 hindley_rosen_lemma) THEN
  PROVE_TAC [beta_CR, eta_CR, eta_beta_commute, commute_COMM]);

val beta_eta_lameta = store_thm(
  "beta_eta_lameta",
  ``conversion (beta RUNION eta) = lameta``,
  SIMP_TAC (srw_ss()) [FUN_EQ_THM, EQ_IMP_THM, FORALL_AND_THM] THEN
  CONJ_TAC THENL [
    SIMP_TAC (srw_ss()) [conversion_def] THEN
    HO_MATCH_MP_TAC equiv_closure_ind THEN
    REPEAT CONJ_TAC THEN1
      (HO_MATCH_MP_TAC compat_closure_ind THEN
       REPEAT CONJ_TAC THEN1
          (SRW_TAC [][beta_def, eta_def, relationTheory.RUNION] THEN
           PROVE_TAC [lameta_rules]) THEN
       PROVE_TAC [lameta_rules]) THEN
    PROVE_TAC [lameta_rules],
    CONV_TAC (RENAME_VARS_CONV ["M", "N"]) THEN HO_MATCH_MP_TAC lameta_ind THEN
    REPEAT STRIP_TAC THENL [
      `(beta RUNION eta) (LAM x M @@ N) ([N/x]M)` by
         (SRW_TAC [][beta_def, relationTheory.RUNION] THEN PROVE_TAC []) THEN
      PROVE_TAC [conversion_rules],
      PROVE_TAC [conversion_rules],
      PROVE_TAC [conversion_rules],
      PROVE_TAC [conversion_rules],
      PROVE_TAC [conversion_compatible, compatible_def, rightctxt,
                 rightctxt_thm],
      PROVE_TAC [conversion_compatible, compatible_def, leftctxt],
      PROVE_TAC [conversion_compatible, compatible_def, absctxt],
      `(beta RUNION eta) (LAM x (N @@ VAR x)) N` by
         (SRW_TAC [][eta_def, relationTheory.RUNION] THEN PROVE_TAC []) THEN
      PROVE_TAC [conversion_rules]
    ]
  ]);

val beta_eta_normal_form_benf = store_thm(
  "beta_eta_normal_form_benf",
  ``normal_form (beta RUNION eta) = benf``,
  SIMP_TAC (srw_ss()) [FUN_EQ_THM, EQ_IMP_THM, benf_def, FORALL_AND_THM,
                       normal_form_def] THEN CONJ_TAC
  THENL [
    Q_TAC SUFF_TAC `!M. ~bnf M \/ ~enf M ==> can_reduce (beta RUNION eta) M`
          THEN1 PROVE_TAC [] THEN
    HO_MATCH_MP_TAC nc_INDUCTION THEN REPEAT CONJ_TAC THENL [
      SRW_TAC [][bnf_thm, enf_thm], (* con case *)
      SRW_TAC [][bnf_thm, enf_thm], (* var case *)
      MAP_EVERY Q.X_GEN_TAC [`f`, `x`] THEN (* app case *)
      SRW_TAC [][bnf_thm, enf_thm] THENL [
        PROVE_TAC [can_reduce_rules],
        PROVE_TAC [can_reduce_rules],
        `redex (beta RUNION eta) (f @@ x)` by
         (SRW_TAC [][redex_def, relationTheory.RUNION, beta_def,
                     EXISTS_OR_THM] THEN
          PROVE_TAC [is_abs_thm, nc_CASES]) THEN
        PROVE_TAC [can_reduce_rules],
        PROVE_TAC [can_reduce_rules],
        PROVE_TAC [can_reduce_rules]
      ],

      MAP_EVERY Q.X_GEN_TAC [`x`, `M`] THEN
      SRW_TAC [][bnf_thm, enf_thm] THENL [
        PROVE_TAC [can_reduce_rules, lemma14a],
        PROVE_TAC [can_reduce_rules, lemma14a],
        Q_TAC SUFF_TAC `redex (beta RUNION eta) (LAM x M)` THEN1
            PROVE_TAC [can_reduce_rules] THEN
        SRW_TAC [][redex_def, relationTheory.RUNION, eta_def] THEN
        PROVE_TAC [is_comb_rator_rand]
      ]
    ],
    Q_TAC SUFF_TAC `!x. can_reduce (beta RUNION eta) x ==> ~bnf x \/ ~enf x`
          THEN1 PROVE_TAC [] THEN
    HO_MATCH_MP_TAC can_reduce_ind THEN
    SIMP_TAC (srw_ss()) [bnf_thm, enf_thm, DISJ_IMP_THM, redex_def,
                         relationTheory.RUNION, GSYM LEFT_FORALL_IMP_THM,
                         beta_def, eta_def]
  ]);

val lameta_consistent = store_thm(
  "lameta_consistent",
  ``consistent lameta``,
  SIMP_TAC (srw_ss()) [consistent_def, GSYM beta_eta_lameta] THEN
  MAP_EVERY Q.EXISTS_TAC [`S`, `K`] THEN STRIP_TAC THEN
  `?Z. reduction (beta RUNION eta) S Z /\ reduction (beta RUNION eta) K Z` by
     PROVE_TAC [theorem3_13, beta_eta_CR] THEN
  `normal_form (beta RUNION eta) S` by
       SRW_TAC [][beta_eta_normal_form_benf, benf_def, bnf_thm, enf_thm,
                  S_def] THEN
  `normal_form (beta RUNION eta) K` by
       SRW_TAC [][beta_eta_normal_form_benf, benf_def, bnf_thm, enf_thm,
                  K_def] THEN
  `S = K` by PROVE_TAC [corollary3_2_1] THEN
  FULL_SIMP_TAC (srw_ss()) [S_def, K_def]);

val rator_subst_commutes = store_thm(
  "rator_subst_commutes",
  ``!t u x. is_comb t ==> ([u/v] (rator t) = rator ([u/v] t))``,
  SRW_TAC [][is_comb_APP_EXISTS, rator_thm, SUB_THM] THEN
  SRW_TAC [][is_comb_APP_EXISTS, rator_thm, SUB_THM]);

val is_comb_subst = store_thm(
  "is_comb_subst",
  ``!t u v. is_comb t ==> is_comb ([u/v]t)``,
  SIMP_TAC (srw_ss()) [SUB_THM, is_comb_APP_EXISTS,
                       GSYM LEFT_FORALL_IMP_THM]);

val rator_isub_commutes = store_thm(
  "rator_isub_commutes",
  ``!R t. is_comb t ==> (rator (t ISUB R) = rator t ISUB R)``,
  Induct THEN
  ASM_SIMP_TAC (srw_ss()) [ISUB_def, pairTheory.FORALL_PROD,
                           rator_subst_commutes, is_comb_subst]);


val SUB_MERGE = store_thm(
  "SUB_MERGE",
  ``!t u v w. ~(v IN FV t) ==> ([VAR u/v] ([VAR v/w] t) = [VAR u/w] t)``,
  REPEAT STRIP_TAC THEN
  Q.SPECL_THEN [`t`, `VAR u`, `VAR u`, `u`, `w`, `v`] ASSUME_TAC
               GENERAL_SUB_COMMUTE THEN
  FULL_SIMP_TAC (srw_ss()) [lemma14a] THEN
  Cases_on `v = u` THEN SRW_TAC [][lemma14a]);

val (hnf_thm, _) =
    define_recursive_term_function
    `(hnf (VAR s) = T) /\
     (hnf (CON k) = T) /\
     (hnf (x @@ y) = hnf x /\ ~is_abs x) /\
     (hnf (LAM v t) = hnf t)`;

val _ = export_theory();

