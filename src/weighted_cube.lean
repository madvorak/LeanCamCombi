/-
Copyright (c) 2022 Yaël Dillies, Kexing Ying. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Kexing Ying
-/
import mathlib.algebra.big_operators.basic
import mathlib.pmf
import probability.ident_distrib
import mathlib.probability.independence

/-!
# Sequences of iid Bernoulli random variables

This file defines sequences of independent `p`-Bernoulli random variables and proves that the
complement of a sequence of independent Bernoulli random variables, union/intersection of two
independent sequences of independent Bernoulli random variables, are themselves sequences of
independent Bernoulli random variables.

## Main declarations

* `probability_theory.bernoulli_seq`: Typeclass for a sequence ``
-/

open measure_theory
open_locale measure_theory probability_theory ennreal nnreal

namespace probability_theory
variables {α Ω : Type*} [measurable_space Ω]

/-- We say a `set α`-valued random is a sequence of iid Bernoulli random variables with parameter
`p` if `p ≤ 1`, the `a` projections (for `a : α`) are independent and are `p`-Bernoulli distributed.
-/
@[protect_proj]
class bernoulli_seq (X : Ω → set α) (p : out_param ℝ≥0) (μ : measure Ω . volume_tac) : Prop :=
(le_one [] : p ≤ 1)
(Indep_fun [] : Indep_fun infer_instance (λ a ω, a ∈ X ω) μ)
(map [] : ∀ a, measure.map (λ ω, a ∈ X ω) μ = (pmf.bernoulli' p le_one).to_measure)

variables (X Y : Ω → set α) (μ : measure Ω) {p q : ℝ≥0} [bernoulli_seq X p μ] [bernoulli_seq Y q μ]
include X p

namespace bernoulli_seq

protected lemma ne_zero [nonempty α] : μ ≠ 0 :=
nonempty.elim ‹_› $ λ a h, (pmf.bernoulli' p $ bernoulli_seq.le_one X μ).to_measure_ne_zero $
  by rw [←bernoulli_seq.map X _ a, h, measure.map_zero]

protected lemma ae_measurable (a : α) : ae_measurable (λ ω, a ∈ X ω) μ :=
begin
  classical,
  have : (pmf.bernoulli' p $ bernoulli_seq.le_one X μ).to_measure ≠ 0 := ne_zero.ne _,
  rw [←bernoulli_seq.map X _ a, measure.map] at this,
  refine (ne.dite_ne_right_iff $ λ hX, _).1 this,
  rw measure.mapₗ_ne_zero_iff hX.measurable_mk,
  haveI : nonempty α := ⟨a⟩,
  exact bernoulli_seq.ne_zero X _,
end

@[simp] protected lemma null_measurable_set (a : α) : null_measurable_set {ω | a ∈ X ω} μ :=
begin
  rw [(by { ext, simp } : {ω | a ∈ X ω} = (λ ω, a ∈ X ω) ⁻¹' {true})],
  exact (bernoulli_seq.ae_measurable X _ a).null_measurable_set_preimage
    measurable_space.measurable_set_top
end

protected lemma ident_distrib (a j : α) : ident_distrib (λ ω, a ∈ X ω) (λ ω, X ω j) μ μ :=
{ ae_measurable_fst := bernoulli_seq.ae_measurable _ _ _,
  ae_measurable_snd := bernoulli_seq.ae_measurable _ _ _,
  map_eq := (bernoulli_seq.map _ _ _).trans (bernoulli_seq.map _ _ _).symm }

@[simp] lemma meas_apply (a : α) : μ {ω | a ∈ X ω} = p :=
begin
  rw [(_ : {ω | a ∈ X ω} = (λ ω, a ∈ X ω) ⁻¹' {true}),
    ← measure.map_apply_of_ae_measurable (bernoulli_seq.ae_measurable X μ a)
      measurable_space.measurable_set_top],
  { simp [bernoulli_seq.map X μ] },
  { ext ω,
    simp }
end

variables [is_probability_measure (μ : measure Ω)]

protected lemma meas [fintype α] (s : finset α) :
  μ {ω | {a | a ∈ X ω} = s} = p ^ s.card * (1 - p) ^ (fintype.card α - s.card) :=
begin
  classical,
  simp_rw [set.ext_iff, set.set_of_forall],
  rw [(bernoulli_seq.Indep_fun X μ).meas_Inter, ←s.prod_mul_prod_compl,
    finset.prod_eq_pow_card _ _ (p : ℝ≥0∞), finset.prod_eq_pow_card _ _ (1 - p : ℝ≥0∞),
    finset.card_compl],
  { rintro a hi,
    rw finset.mem_compl at hi,
    simp only [hi, ←set.compl_set_of, null_measurable_set.prob_compl_eq_one_sub, set.mem_set_of_eq,
      finset.mem_coe, iff_false, bernoulli_seq.null_measurable_set, meas_apply] },
  { rintro a hi,
    simp only [hi, set.mem_set_of_eq, finset.mem_coe, iff_true, meas_apply] },
  rintro a,
  by_cases a ∈ s,
  { simp only [*, set.mem_set_of_eq, finset.mem_coe, iff_true],
    exact ⟨{true}, trivial, by { ext, simp }⟩ },
  { simp only [*, set.mem_set_of_eq, finset.mem_coe, iff_false],
    exact ⟨{false}, trivial, by { ext, simp }⟩ }
end

/-- The complement of a sequence of independent `p`-Bernoulli random variables is a sequence of
independent `1 - p`-Bernoulli random variables. -/
instance compl : bernoulli_seq (λ ω, (X ω)ᶜ) (1 - p) μ :=
{ le_one := tsub_le_self,
  Indep_fun :=
  begin
    simp only [Indep_fun, set.mem_compl_iff, measurable_space.comap_not],
    exact bernoulli_seq.Indep_fun X _,
  end,
  map := λ a, begin
    have : measurable not := λ _ _, trivial,
    simp only [set.mem_compl_iff],
    rw [←this.ae_measurable.map_map_of_ae_measurable (bernoulli_seq.ae_measurable X μ _),
      bernoulli_seq.map, pmf.map_to_measure _ this, pmf.map_not_bernoulli'],
  end }

/-- The intersection of a sequence of independent `p`-Bernoulli and `q`-Bernoulli random variables
is a sequence of independent `p * q`-Bernoulli random variables. -/
protected lemma inter (h : indep_fun X Y μ) : bernoulli_seq (λ ω, X ω ∩ Y ω) (p * q) μ :=
{ le_one := mul_le_one' (bernoulli_seq.le_one X μ) (bernoulli_seq.le_one Y μ),
  Indep_fun :=
  begin
    refine Indep_set.Indep_comap ((Indep_set_iff_measure_Inter_eq_prod $ λ i, _).2 _),
    refine measurable_set.inter _ _,
    sorry, -- needs refactor of `probability.independence`
    sorry, -- needs refactor of `probability.independence`
    refine λ s, _,
    -- We abused defeq using `Indep_set.Indep_comap`, so we fix it here
    change μ (⋂ i ∈ s, {ω | X ω i} ∩ {ω | Y ω i}) = s.prod (λ i, μ ({ω | X ω i} ∩ {ω | Y ω i})),
    simp_rw set.Inter_inter_distrib,
    rw [h, bernoulli_seq.Indep_fun X μ, bernoulli_seq.Indep_fun Y μ, ←finset.prod_mul_distrib],
    refine finset.prod_congr rfl (λ i hi, (h _ _ _ _).symm),
    sorry, -- needs refactor of `probability.independence`
    sorry, -- needs refactor of `probability.independence`
    sorry, -- needs refactor of `probability.independence`
    sorry, -- needs refactor of `probability.independence`
    sorry, -- needs refactor of `probability.independence`
    sorry, -- needs refactor of `probability.independence`
  end,
  map := begin
    rintro a,
    sorry
  end }

/-- The union of a sequence of independent `p`-Bernoulli random variables is a sequence of
independent `1 - p`-Bernoulli random variables. -/
protected lemma union (h : indep_fun X Y μ) : bernoulli_seq (λ ω, X ω ∪ Y ω) (p + q - p * q) μ :=
begin
  haveI := bernoulli_seq.inter (λ ω, (X ω)ᶜ) (λ ω, (Y ω)ᶜ) μ _,
  convert bernoulli_seq.compl (λ ω, (X ω)ᶜ ∩ (Y ω)ᶜ) μ using 1,
  simp only [set.compl_inter, compl_compl],
  rw [mul_tsub, mul_one, tsub_tsub, tsub_tsub_cancel_of_le, tsub_mul, one_mul,
    add_tsub_assoc_of_le (mul_le_of_le_one_left' $ bernoulli_seq.le_one X μ)],
  { exact (add_le_add_left (mul_le_of_le_one_right' $ bernoulli_seq.le_one Y μ) _).trans_eq
      (add_tsub_cancel_of_le $ bernoulli_seq.le_one X μ) },
  rwa [indep_fun, measurable_space.comap_compl, measurable_space.comap_compl]; exact λ _ _, trivial,
end

end bernoulli_seq
end probability_theory
