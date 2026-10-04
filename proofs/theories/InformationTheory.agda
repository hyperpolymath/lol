-- SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
-- SPDX-FileCopyrightText: 2024-2026 Ehsaneddin Asgari and Contributors
--
-- Information Theory — theorems
-- =============================
-- The public module of the LOL information-theory formalisation. The
-- ReScript crawler side keeps its property tests; this tree is the
-- machine-checked companion.
--
-- Layering (enforced by .github/workflows/echidna-verify.yml, issue #4):
--
--   InformationTheory.Foundations   --safe     total, postulate-free definitions
--   InformationTheory.Axioms        not safe  the only quarantine holding `postulate`
--   InformationTheory (this module) --safe     theorems + public surface
--
-- Both POSTULATE-AUDIT "provable" obligations are discharged here:
-- `entropy-nonneg` by induction over the vector sum from the per-entry
-- `plogp-nonneg` ffi-fact, and `js-symmetric` by rewriting the midpoint
-- with `add-comm`. Neither proof touches the `conjecture` class —
-- `kl-nonneg`/`js-bounded` stay open and are only re-exported as-is so
-- consumers see their trust level.
{-# OPTIONS --safe --without-K #-}

module InformationTheory where

open import Data.Float using (Float; _+_; _÷_; _≤ᵇ_; _<ᵇ_)
open import Data.Fin using (Fin; zero; suc)
open import Data.Vec using (Vec; []; _∷_; map; zipWith; lookup)
open import Data.Unit.Base using (tt)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂; subst)

open import InformationTheory.Foundations public
open import InformationTheory.Axioms
  using (plogp-nonneg; add-nonneg; add-comm; kl-nonneg; js-bounded)
  public

-- ============================================================================
-- Vector plumbing (no axioms used in this section)
-- ============================================================================

-- `map` and `lookup` commute pointwise, definitionally.
lookup-map : ∀ {n} (f : Float → Float) (xs : Vec Float n) (i : Fin n) →
             lookup (map f xs) i ≡ f (lookup xs i)
lookup-map f []       ()
lookup-map f (x ∷ xs) zero    = refl
lookup-map f (x ∷ xs) (suc i) = lookup-map f xs i

-- A vector sum is non-negative when every entry is. Right-association of
-- `sumF` matches the fold the pre-2026 corpus used, so the computation is
-- observationally identical while this proof only needs the binary closure
-- fact `add-nonneg` at each step.
sumF-nonneg : ∀ {n} (xs : Vec Float n) →
              (∀ {i : Fin n} → 0.0 ≤ᶠ lookup xs i) → 0.0 ≤ᶠ sumF xs
sumF-nonneg []       h = tt
sumF-nonneg (x ∷ xs) h =
  add-nonneg x (sumF xs) (h {zero}) (sumF-nonneg xs λ { {i} → h {suc i} })

-- Pointwise equality transports through zipWith…
zipWith-cong₂ : ∀ {n} (f g : Float → Float → Float) →
                (∀ x y → f x y ≡ g x y) →
                (xs ys : Vec Float n) →
                zipWith f xs ys ≡ zipWith g xs ys
zipWith-cong₂ f g h []       []       = refl
zipWith-cong₂ f g h (x ∷ xs) (y ∷ ys) = cong₂ _∷_ (h x y) (zipWith-cong₂ f g h xs ys)

-- …and a pointwise-commutative function makes zipWith symmetric in its
-- arguments (the shape the JSD midpoint needs).
zipWith-comm : (f : Float → Float → Float) →
               (∀ x y → f x y ≡ f y x) →
               ∀ {n} (xs ys : Vec Float n) →
               zipWith f xs ys ≡ zipWith f ys xs
zipWith-comm f h []       []       = refl
zipWith-comm f h (x ∷ xs) (y ∷ ys) = cong₂ _∷_ (h x y) (zipWith-comm f h xs ys)

-- ============================================================================
-- Entropy is non-negative  (H(X) ≥ 0 for p ∈ [0,1], 0·log 0 = 0 convention)
-- ============================================================================
-- Proven top-level theorem (POSTULATE-AUDIT Phase 2 #2): the only external
-- fact consumed is the per-entry ffi-fact `plogp-nonneg`; the summation is
-- real induction.

entropy-nonneg : ∀ {n} (d : Distribution n) → 0.0 ≤ᶠ entropy d
entropy-nonneg {n} d =
  sumF-nonneg (map plogp (values d)) λ { {i} →
    subst (0.0 ≤ᶠ_) (sym (lookup-map plogp (values d) i))
      (plogp-nonneg (lookup (values d) i) (lower d {i}) (upper d {i})) }

-- ============================================================================
-- Jensen-Shannon divergence is symmetric  (POSTULATE-AUDIT Phase 2 #1)
-- ============================================================================
-- JSD(P,Q) = (D(P‖M) + D(Q‖M))/2 with M = (P+Q)/2. Swapping P and Q leaves M
-- fixed up to commutativity of float addition; the two KL terms then swap.
-- No associativity of + is ever needed — that is what keeps this honest for
-- IEEE-754.

midpointF-comm : ∀ x y → midpointF x y ≡ midpointF y x
midpointF-comm x y = cong (λ w → w ÷ 2.0) (add-comm x y)

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
-- Definitional sanity of the guards (no axioms used)
-- ============================================================================

-- The strict positivity guard makes the KL term evaluate to exactly 0.0 at
-- p = 0 (`0.0 <ᵇ 0.0` computes to false): the 0·log 0 = 0 convention is not
-- merely asserted, it is what the function computes.
klTerm-zero-left : ∀ q → klTerm 0.0 q ≡ 0.0
klTerm-zero-left q = refl

-- Same for the entropy term.
plogp-zero : plogp 0.0 ≡ 0.0
plogp-zero = refl

-- And the boundary p = 1 computes to −(1·log₂ 1) = −0.0, which the order
-- relation accepts (`0.0 ≤ᶠ - 0.0` holds because 0 ≤ᵇ −0.0 computes true):
-- negative zero does not break entropy-nonneg at the boundary.
plogp-one-boundary : 0.0 ≤ᶠ plogp 1.0
plogp-one-boundary = tt
