/-
Copyright (c) 2022 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import Mathlib.Data.Fintype.Order
import Mathlib.Order.Irreducible
import Mathlib.Order.UpperLower.Basic
import LeanCamCombi.Mathlib.Data.Fintype.Basic
import LeanCamCombi.Mathlib.Order.BoundedOrder
import LeanCamCombi.Mathlib.Order.LocallyFinite
import LeanCamCombi.Mathlib.Order.UpperLower.Basic

/-!
# Birkhoff's representation theorem

This file proves the Birkhoff representation theorem: Any finite distributive lattice can be represented as a sublattice of some powerset algebra.

Precisely, any nonempty finite distributive lattice is isomorphic to the lattice of lower sets of
its irreducible elements. And conversely it is isomorphic to the order of its irreducible lower
sets.

## Main declarations

For a nonempty finite distributive lattice `α`:
* `OrderIso.lowerSetSupIrred`: `α` is isomorphic to the lattice of lower sets of its irreducible
  elements.
* `OrderIso.supIrredLowerSet`: `α` is isomorphic to the order of its irreducible lower sets.
* `OrderEmbedding.birkhoffSet`, `OrderEmbedding.birkhoffFinet`: Order embedding of `α` into the
  powerset lattice of its irreducible elements.
* `LatticeHom.birkhoffSet`, `LatticeHom.birkhoffFinet`: Same as the previous two, but bundled as
  an injective lattice homomorphism.
* `exists_birkhoff_representation`: `α` embeds into some powerset algebra. You should prefer using
  this over the explicit Birkhoff embedding because the Birkhoff embedding is littered with
  decidability footguns that this existential-packaged version can afford to avoid.

## See also

This correspondance between finite distributive lattices and finite boolean algebras is made
functorial in... TODO: Actually do it.

## Tags

birkhoff, representation, stone duality, lattice embedding
-/

open Finset Function OrderDual

variable {α : Type*}

namespace UpperSet
variable [SemilatticeInf α] {s : UpperSet α} {a : α}

@[simp] lemma infIrred_Ici (a : α) : InfIrred (Ici a) := by
  refine' ⟨λ h ↦ Ici_ne_top _ h.eq_top, λ s t hst ↦ _⟩
  have := mem_Ici_iff.2 (le_refl a)
  rw [←hst] at this
  exact this.imp (λ ha ↦ le_antisymm (le_Ici.2 ha) $ hst.ge.trans inf_le_left) λ ha ↦
      le_antisymm (le_Ici.2 ha) $ hst.ge.trans inf_le_right

variable [Finite α]

@[simp] protected lemma infIrred : InfIrred s ↔ ∃ a, Ici a = s := by
  refine' ⟨λ hs ↦ _, _⟩
  · obtain ⟨a, ha, has⟩ := (s : Set α).toFinite.exists_minimal_wrt id _ (coe_nonempty.2 hs.ne_top)
    exact ⟨a, (hs.2 $ erase_inf_Ici has ha).resolve_left (lt_erase ha).ne'⟩
  · rintro ⟨a, rfl⟩
    exact infIrred_Ici _

end UpperSet

namespace LowerSet
variable [SemilatticeSup α] {s : LowerSet α} {a : α}

@[simp] lemma supIrred_Iic (a : α) : SupIrred (Iic a) := by
  refine' ⟨λ h ↦ Iic_ne_bot _ h.eq_bot, λ s t hst ↦ _⟩
  have := mem_Iic_iff.2 (le_refl a)
  rw [←hst] at this
  exact this.imp (λ ha ↦ (le_sup_left.trans_eq hst).antisymm $ Iic_le.2 ha) λ ha ↦
    (le_sup_right.trans_eq hst).antisymm $ Iic_le.2 ha

variable [Finite α]

@[simp] protected lemma supIrred : SupIrred s ↔ ∃ a, Iic a = s := by
  refine' ⟨λ hs ↦ _, _⟩
  · obtain ⟨a, ha, has⟩ := (s : Set α).toFinite.exists_maximal_wrt id _ (coe_nonempty.2 hs.ne_bot)
    exact ⟨a, (hs.2 $ erase_sup_Iic has ha).resolve_left (erase_lt ha).ne⟩
  · rintro ⟨a, rfl⟩
    exact supIrred_Iic _

end LowerSet

section DistribLattice
variable [DistribLattice α]

section Fintype
variable [Fintype α] [OrderBot α]

open scoped Classical

/-- **Birkhoff's Representation Theorem**. Any nonempty finite distributive lattice is isomorphic to
the lattice of lower sets of its sup-irreducible elements. -/
noncomputable def OrderIso.lowerSetSupIrred : α ≃o LowerSet {a : α // SupIrred a} :=
  Equiv.toOrderIso
    { toFun := λ a ↦ ⟨{b | ↑b ≤ a}, λ b c hcb hba ↦ hba.trans' hcb⟩
      invFun := λ s ↦ (s : Set {a : α // SupIrred a}).toFinset.sup (↑)
      left_inv := λ a ↦ by
        refine' le_antisymm (Finset.sup_le λ b ↦ Set.mem_toFinset.1) _
        obtain ⟨s, rfl, hs⟩ := exists_supIrred_decomposition a
        exact Finset.sup_le λ i hi ↦
          le_sup_of_le (b := ⟨i, hs hi⟩) (Set.mem_toFinset.2 $ le_sup (f := id) hi) le_rfl
      right_inv := λ s ↦ by
        ext a
        dsimp
        refine' ⟨λ ha ↦ _, λ ha ↦ _⟩
        · obtain ⟨i, hi, ha⟩ := a.2.supPrime.le_finset_sup.1 ha
          exact s.lower ha (Set.mem_toFinset.1 hi)
        · dsimp
          exact le_sup (Set.mem_toFinset.2 ha) }
    (λ b c hbc d ↦ le_trans' hbc) λ s t hst ↦ Finset.sup_mono $ Set.toFinset_mono hst

attribute [-instance] Set.fintypeIic

/-- Any nonempty finite distributive lattice is isomorphic to its lattice of sup-irreducible lower
sets. -/
noncomputable def OrderIso.supIrredLowerSet : α ≃o {s : LowerSet α // SupIrred s} :=
  Equiv.toOrderIso
    { toFun := λ a ↦ ⟨LowerSet.Iic a, LowerSet.supIrred_Iic _⟩
      invFun := λ s ↦ ((s : LowerSet α) : Set α).toFinset.sup id
      left_inv := λ a ↦ by
        have : LocallyFiniteOrder α := Fintype.toLocallyFiniteOrder
        simp
      right_inv := by
        classical
        have : LocallyFiniteOrder α := Fintype.toLocallyFiniteOrder
        rintro ⟨s, hs⟩
        obtain ⟨a, rfl⟩ := LowerSet.supIrred.1 hs
        simp }
    (λ b c hbc d ↦ le_trans' hbc) λ s t hst ↦ Finset.sup_mono $ Set.toFinset_mono hst

end Fintype

variable (α)

namespace OrderEmbedding
variable [Fintype α] [@DecidablePred α SupIrred]

/-- **Birkhoff's Representation Theorem**. Any finite distributive lattice can be embedded in a
powerset lattice. -/
noncomputable def birkhoffSet : α ↪o Set {a : α // SupIrred a} := by
  by_cases IsEmpty α
  · exact ⟨⟨isEmptyElim, isEmptyElim⟩, isEmptyElim ‹α›, isEmptyElim ‹α›⟩
  rw [not_isEmpty_iff] at h
  have := Fintype.toOrderBot α
  exact OrderIso.lowerSetSupIrred.toOrderEmbedding.trans ⟨⟨_, SetLike.coe_injective⟩, Iff.rfl⟩

/-- **Birkhoff's Representation Theorem**. Any finite distributive lattice can be embedded in a
powerset lattice. -/
noncomputable def birkhoffFinset : α ↪o Finset {a : α // SupIrred a} := by
  exact (birkhoffSet _).trans Fintype.finsetOrderIsoSet.symm.toOrderEmbedding

variable {α}

@[simp] lemma coe_birkhoffFinset (a : α) : birkhoffFinset α a = birkhoffSet α a := by
  classical
  simp [birkhoffFinset]
  rw [OrderIso.coe_toOrderEmbedding, Fintype.coe_finsetOrderIsoSet_symm]
  simp

@[simp] lemma birkhoffSet_sup (a b : α) :
    birkhoffSet α (a ⊔ b) = birkhoffSet α a ∪ birkhoffSet α b := by
  unfold OrderEmbedding.birkhoffSet; split <;> simp

@[simp] lemma birkhoffSet_inf (a b : α) :
    birkhoffSet α (a ⊓ b) = birkhoffSet α a ∩ birkhoffSet α b := by
  unfold OrderEmbedding.birkhoffSet; split <;> simp

variable [DecidableEq α]

@[simp] lemma birkhoffFinset_sup (a b : α) :
    birkhoffFinset α (a ⊔ b) = birkhoffFinset α a ∪ birkhoffFinset α b := by
  dsimp [OrderEmbedding.birkhoffFinset]
  rw [birkhoffSet_sup, OrderIso.coe_toOrderEmbedding]
  simpa using OrderIso.map_sup _ _ _

@[simp] lemma birkhoffFinset_inf (a b : α) :
    birkhoffFinset α (a ⊓ b) = birkhoffFinset α a ∩ birkhoffFinset α b := by
  dsimp [OrderEmbedding.birkhoffFinset]
  rw [birkhoffSet_inf, OrderIso.coe_toOrderEmbedding]
  simpa using OrderIso.map_inf _ _ _

variable [OrderBot α]

@[simp] lemma birkhoffSet_apply (a : α) : birkhoffSet α a = OrderIso.lowerSetSupIrred a := by
  simp [birkhoffSet]; convert rfl

end OrderEmbedding

namespace LatticeHom
variable [Fintype α] [DecidableEq α] [@DecidablePred α SupIrred]

/-- **Birkhoff's Representation Theorem**. Any finite distributive lattice can be embedded in a
powerset lattice. -/
noncomputable def birkhoffSet : LatticeHom α (Set {a : α // SupIrred a}) where
  toFun := OrderEmbedding.birkhoffSet α
  map_sup' := OrderEmbedding.birkhoffSet_sup
  map_inf' := OrderEmbedding.birkhoffSet_inf

/-- **Birkhoff's Representation Theorem**. Any finite distributive lattice can be embedded in a
powerset lattice. -/
noncomputable def birkhoffFinset : LatticeHom α (Finset {a : α // SupIrred a}) where
  toFun := OrderEmbedding.birkhoffFinset α
  map_sup' := OrderEmbedding.birkhoffFinset_sup
  map_inf' := OrderEmbedding.birkhoffFinset_inf

lemma birkhoffFinset_injective : Injective (birkhoffFinset α) :=
  (OrderEmbedding.birkhoffFinset α).injective

end LatticeHom

lemma exists_birkhoff_representation.{u} (α : Type u) [Finite α] [DistribLattice α] :
    ∃ (β : Type u) (_ : DecidableEq β) (_ : Fintype β) (f : LatticeHom α (Finset β)),
      Injective f := by
  classical
  cases nonempty_fintype α
  exact ⟨{a : α // SupIrred a}, _ , by infer_instance, _, LatticeHom.birkhoffFinset_injective _⟩

end DistribLattice
