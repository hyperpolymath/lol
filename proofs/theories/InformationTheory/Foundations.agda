-- SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
-- SPDX-FileCopyrightText: 2024-2026 Ehsaneddin Asgari and Contributors
--
-- Information Theory — computational foundations
-- ==============================================
-- Every definition the `InformationTheory` theorems quantify over, as
-- total postulate-free Agda. Trusted facts (IEEE-754 float properties and
-- the two open information-theoretic conjectures) live in
-- `InformationTheory.Axioms`, the single quarantined trust base.
--
-- This module is checked with `--safe` by
-- .github/workflows/echidna-verify.yml (issue #4); adding a `postulate`
-- here is rejected by Agda itself.
{-# OPTIONS --safe --without-K #-}

module InformationTheory.Foundations where

open import Data.Bool.Base using (Bool; true; false; T; if_then_else_)
open import Data.Float public
  using (Float; _+_; _*_; _÷_; -_; log; _≤ᵇ_; _≡ᵇ_; _<ᵇ_)
open import Data.Fin using (Fin)
open import Data.Nat using (ℕ)
open import Data.Vec using (Vec; []; _∷_; map; zipWith; lookup)
open import Relation.Binary.PropositionalEquality using (_≡_)

-- ============================================================================
-- Order relations on Float — honest and non-vacuous
-- ============================================================================
-- Each proposition is `T` applied to the runtime comparison primitive, so it
-- computes to a decidable claim about IEEE-754 values (`T true = ⊤`,
-- `T false = ⊥`). This replaces the pre-2026 corpus's per-postulate
-- `where _≥_ : Float → Float → Set` declarations, which were uninterpreted
-- relations satisfied vacuously by every pair of floats. See
-- proofs/POSTULATE-AUDIT.adoc ("Additional concerns").

infix 4 _≤ᶠ_ _≥ᶠ_ _<ᶠ_

_≤ᶠ_ : Float → Float → Set
x ≤ᶠ y = T (x ≤ᵇ y)

_<ᶠ_ : Float → Float → Set
x <ᶠ y = T (x <ᵇ y)

_≥ᶠ_ : Float → Float → Set
x ≥ᶠ y = y ≤ᶠ x

-- ============================================================================
-- Logarithms and per-entry terms
-- ============================================================================

-- log base 2, via the float primitives (ln x / ln 2).
log₂ : Float → Float
log₂ v = log v ÷ log 2.0

-- −p·log₂ p with the usual 0·log 0 = 0 convention. The zero-test result is
-- an explicit Boolean argument so downstream theorems can case-analyse it
-- without stuck with-abstraction on a Float primitive; `plogp` is the entry
-- point used in definitions.
plogpB : Float → Bool → Float
plogpB v b = if b then 0.0 else - (v * log₂ v)

plogp : Float → Float
plogp v = plogpB v (v ≡ᵇ 0.0)

-- p·log₂(p/q) for KL terms, guarding p = 0 (the q = 0 case legitimately
-- yields +∞ rather than a special value).
klTermB : Float → Float → Bool → Float
klTermB p q b = if b then 0.0 else p * log₂ (p ÷ q)

klTerm : Float → Float → Float
klTerm p q = klTermB p q (p ≡ᵇ 0.0)

-- Pointwise (P + Q)/2, the JSD midpoint construction.
midpointF : Float → Float → Float
midpointF x y = (x + y) ÷ 2.0

-- ============================================================================
-- Sums and distributions
-- ============================================================================

-- Right-associated fold over a vector of floats; observationally equal to
-- `Data.Vec.foldr (λ _ → Float) _+_ 0.0` but shaped for induction.
sumF : ∀ {n} → Vec Float n → Float
sumF []       = 0.0
sumF (x ∷ xs) = x + sumF xs

-- A distribution over n outcomes: every entry lies in [0, 1] as decided by
-- the float comparison primitives (which exclude NaN, since NaN fails every
-- comparison), and the float sum is exactly 1.0. These hypotheses make the
-- theorems in `InformationTheory` true statements — the pre-2026 corpus had
-- unconstrained `Probability` records and was refutable (e.g. p = 2.0 makes
-- −p·log₂ p < 0, and unnormalised p/q trivially breaks Gibbs).
record Distribution (n : ℕ) : Set where
  constructor mkDist
  field
    values     : Vec Float n
    lower      : ∀ {i : Fin n} → 0.0 ≤ᶠ lookup values i
    upper      : ∀ {i : Fin n} → lookup values i ≤ᶠ 1.0
    normalised : sumF values ≡ 1.0

-- Projections (and `mkDist`) into scope for the definitions below and for
-- consumers that re-export this module.
open Distribution public

-- ============================================================================
-- Divergences
-- ============================================================================

-- Shannon entropy: H(X) = −Σ p(x) log₂ p(x), bits.
entropy : ∀ {n} → Distribution n → Float
entropy {n} d = sumF (map plogp (values d))

-- KL-divergence on raw vectors: D(P‖Q) = Σ p·log₂(p/q).
kl-divergenceF : ∀ {n} → Vec Float n → Vec Float n → Float
kl-divergenceF ps qs = sumF (zipWith klTerm ps qs)

-- KL-divergence on distributions.
kl-divergence : ∀ {n} → Distribution n → Distribution n → Float
kl-divergence p q = kl-divergenceF (values p) (values q)

-- Jensen-Shannon divergence on raw vectors: with M = (P + Q)/2,
-- JSD = (D(P‖M) + D(Q‖M))/2.
jsdF : ∀ {n} → Vec Float n → Vec Float n → Float
jsdF ps qs = ((kl-divergenceF ps m) + (kl-divergenceF qs m)) ÷ 2.0
  where m = zipWith midpointF ps qs

-- Jensen-Shannon divergence on distributions.
jensen-shannon : ∀ {n} → Distribution n → Distribution n → Float
jensen-shannon p q = jsdF (values p) (values q)
