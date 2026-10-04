-- SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
-- SPDX-FileCopyrightText: 2024-2026 Ehsaneddin Asgari and Contributors
--
-- Information Theory — theorems
-- =============================
-- The public module of the LOL information-theory formalisation
-- (1000Langs/ReScript side keeps its own property tests; this tree is the
-- machine-checked companion).
--
-- Layering (enforced by .github/workflows/echidna-verify.yml, issue #4):
--
--   InformationTheory.Foundations   --safe   total, postulate-free definitions
--   InformationTheory.Axioms        not safe  the only quarantine holding `postulate`
--   InformationTheory (this module) --safe   theorems + public surface
--
-- The two theorems POSTULATE-AUDIT classified as "provable" (`entropy-nonneg`,
-- `js-symmetric`) are proven here — from the four IEEE-754 `ffi-fact` axioms,
-- never from the `conjecture` class. `kl-nonneg` and `js-bounded` remain
-- tagged conjectures (Phase 2 open), re-exported so dependents see the
-- trust level.
{-# OPTIONS --safe --without-K #-}

module InformationTheory where

open import Data.Bool.Base using (Bool; true; false; T)
open import Data.Float using (Float; _+_; _÷_; _≤ᵇ_; _≡ᵇ_)
open import Data.Fin using (Fin; zero; suc)
open import Data.Nat using (ℕ)
open import Data.Product using (_×_; _,_)
open import Data.Vec using (Vec; []; _∷_; map; zipWith; lookup)
open import Data.Unit.Base using (tt)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂; subst)

open import InformationTheory.Foundations public
open import InformationTheory.Axioms
  using (log₂-nonpos; mul-sign; add-nonneg; add-comm; kl-nonneg; js-bounded)
  public

-- ============================================================================
-- Vector plumbing
-- ============================================================================

lookup-map : ∀ {n} (f : Float → Float) (xs : Vec Float n) (i : Fin n) →
             lookup (map f xs) i ≡ f (lookup xs i)
lookup-map f []       ()
lookup-map f (x ∷ xs) zero    = refl
lookup-map f (x ∷ xs) (suc i) = lookup-map f xs i

-- The float sum of a vector is non-negative when all entries are.
sumF-nonneg : ∀ {n} (xs : Vec Float n) →
              (∀ {i : Fin n} → 0.0 ≤ᶠ lookup xs i) → 0.0 ≤ᶠ sumF xs
sumF-nonneg []       h = tt
sumF-nonneg (x ∷ xs) h =
  add-nonneg x (sumF xs) (h {zero}) (sumF-nonneg xs λ { {i} → h {suc i} })

-- Pointwise equality transports through zipWith, and a commutative pointwise
-- function makes zipWith itself symmetric in its arguments.
zipWith-cong₂ : ∀ {n} (f g : Float → Float → Float) →
                (∀ x y → f x y ≡ g x y) →
                (xs ys : Vec Float n) →
                zipWith f xs ys ≡ zipWith g xs ys
zipWith-cong₂ f g h []       []       = refl
zipWith-cong₂ f g h (x ∷ xs) (y ∷ ys) = cong₂ _∷_ (h x y) (zipWith-cong₂ f g h xs ys)

zipWith-comm : (f : Float → Float → Float) →
               (∀ x y → f x y ≡ f y x) →
               ∀ {n} (xs ys : Vec Float n) →
               zipWith f xs ys ≡ zipWith f ys xs
zipWith-comm f h []       []       = refl
zipWith-comm f h (x ∷ xs) (y ∷ ys) = cong₂ _∷_ (h x y) (zipWith-comm f h xs ys)

-- ============================================================================
-- Entropy is non-negative (H ≥ 0 for p ∈ [0,1], per-entry 0·log 0 = 0)
-- ============================================================================

-- Per-entry fact: the guarded −v·log₂ v is non-negative on [0,1].
plogpB-nonneg : (v : Float) → 0.0 ≤ᶠ v → v ≤ᶠ 1.0 →
                (b : Bool) → 0.0 ≤ᶠ plogpB v b
plogpB-nonneg v lv lu true  = tt
plogpB-nonneg v lv lu false = mul-sign v (log₂ v) lv (log₂-nonpos v lv lu)

plogp-nonneg : (v : Float) → 0.0 ≤ᶠ v → v ≤ᶠ 1.0 → 0.0 ≤ᶠ plogp v
plogp-nonneg v lv lu = plogpB-nonneg v lv lu (v ≡ᵇ 0.0)

entropy-nonneg : ∀ {n} (d : Distribution n) → 0.0 ≤ᶠ entropy d
entropy-nonneg {n} d =
  sumF-nonneg (map plogp (values d)) λ { {i} →
    subst (0.0 ≤ᶠ_) (sym (lookup-map plogp (values d) i))
      (plogp-nonneg (lookup (values d) i) (lower d {i}) (upper d {i})) }

-- ============================================================================
-- Jensen-Shannon divergence is symmetric
-- ============================================================================

midpointF-comm : ∀ x y → midpointF x y ≡ midpointF y x
midpointF-comm x y = cong (λ w → w ÷ 2.0) (add-comm x y)

-- JSD(P,Q) = (D(P‖M) + D(Q‖M))/2 with M = (P+Q)/2. Swapping P and Q leaves M
-- fixed up to commutativity of float addition, then the two KL terms swap.
js-symmetric : ∀ {n} (p q : Distribution n) →
               jensen-shannon p q ≡ jensen-shannon q p
js-symmetric {n} p q = cong (λ w → w ÷ 2.0) (trans swapKL rezip)
  where
    pv qv : Vec Float n
    pv = values p
    qv = values q

    mm : zipWith midpointF pv qv ≡ zipWith midpointF qv pv
    mm = zipWith-comm midpointF midpointF-comm pv qv

    swapKL : kl-divergenceF pv (zipWith midpointF pv qv)
               + kl-divergenceF qv (zipWith midpointF pv qv)
             ≡ kl-divergenceF qv (zipWith midpointF pv qv)
               + kl-divergenceF pv (zipWith midpointF pv qv)
    swapKL = add-comm _ _

    rezip : kl-divergenceF qv (zipWith midpointF pv qv)
              + kl-divergenceF pv (zipWith midpointF pv qv)
            ≡ kl-divergenceF qv (zipWith midpointF qv pv)
              + kl-divergenceF pv (zipWith midpointF qv pv)
    rezip = cong₂ _+_ (cong (kl-divergenceF qv) mm) (cong (kl-divergenceF pv) mm)

-- ============================================================================
-- Sanity of the definitions themselves (no axioms used)
-- ============================================================================

-- The zero-guard on the KL term agrees with the 0·log convention at p = 0:
-- `0.0 ≡ᵇ 0.0` computes to true, so the term reduces.
klTerm-zero-left : ∀ q → klTerm 0.0 q ≡ 0.0
klTerm-zero-left q = refl

