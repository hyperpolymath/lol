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

open import Data.Bool.Base using (T; if_then_else_)
open import Data.Float public
  using (Float; _+_; _*_; _÷_; -_; log; _≤ᵇ_; _<ᵇ_)
open import Data.Fin.Base using (Fin)
open import Data.Nat using (ℕ)
open import Data.Vec.Base using (Vec; []; _∷_; map; zipWith; lookup)
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

-- −p·log₂ p with the usual 0·log 0 = 0 convention.
--
-- The guard is *strict positivity* (0.0 <ᵇ v), not a zero test. Reason (the
-- PR #18 review lesson): under IEEE-754, `0 * log₂ 0 = 0 * (−∞) = NaN`, so a
-- definition that branches on `v ≡ᵇ 0.0` computes NaN for ±0/−∞-adjacent
-- inputs and any axiom of the shape "0 ≤ v → … → 0 ≤ −(v·log₂v)" becomes
-- refutable at v = 0 — a refutable axiom inhabits ⊥ and proves everything,
-- which is exactly the class of bug this rebuild set out to kill. With the
-- strict guard, the out-of-domain side of the conditional *is* the value the
-- convention prescribes (0.0), the function is NaN-safe for every input, and
-- the accompanying FFI axiom (InformationTheory.Axioms) needs no side
-- conditions beyond the in-band bounds. v = 1 gives −(1·0) = −0.0, and
-- `0 ≤ᵇ −0.0` computes to true, so the boundary is consistent too.
plogp : Float → Float
plogp v = if 0.0 <ᵇ v then - (v * log₂ v) else 0.0

-- p·log₂(p/q) for KL terms, guarded the same way. The q = 0 case with
-- p > 0 legitimately yields p·log₂(+∞) = +∞ rather than a special value.
klTerm : Float → Float → Float
klTerm p q = if 0.0 <ᵇ p then p * log₂ (p ÷ q) else 0.0

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
-- The midpoint is written out in both clauses rather than bound by a
-- `where`: a where-clause of a definition becomes a local module that
-- unification cannot always unfold through when the importer also matches
-- under it (live CI evidence: "blocked on _a_" while proving js-symmetric),
-- so the construction stays fully transparent.
jsdF : ∀ {n} → Vec Float n → Vec Float n → Float
jsdF ps qs =
  (kl-divergenceF ps (zipWith midpointF ps qs)
   + kl-divergenceF qs (zipWith midpointF ps qs)) ÷ 2.0

-- Jensen-Shannon divergence on distributions.
jensen-shannon : ∀ {n} → Distribution n → Distribution n → Float
jensen-shannon p q = jsdF (values p) (values q)
