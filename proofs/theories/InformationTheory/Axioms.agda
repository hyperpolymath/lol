-- SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
-- SPDX-FileCopyrightText: 2024-2026 Ehsaneddin Asgari and Contributors
--
-- Information Theory — quarantined trust base
-- ============================================
-- This is the ONLY module in the corpus allowed to contain `postulate`.
-- It is deliberately compiled WITHOUT `--safe` (Agda's --safe rejects
-- postulates outright — test/Fail/SafeFlagPostulate in the Agda tree), so
-- the quarantine is enforced mechanically by
-- .github/workflows/echidna-verify.yml (issue #4):
--
--   * `grep postulate` outside this file is a hard CI failure;
--   * every postulate declaration carries an `ECHIDNA:trust <class> :: <name>`
--     tag on the line above it;
--   * names, classes and counts must match proofs/trust-base.json exactly
--     (see scripts/audit-trust-base.py and proofs/POSTULATE-AUDIT.adoc).
--
-- Classes:
--   ffi-fact     — a true property of correctly-rounded IEEE-754 operations
--                  that Agda cannot derive from its opaque Float primitives.
--                  Removing this file's --safe flag is what admits them; the
--                  theorems that consume them are still fully checked.
--   conjecture   — a classical theorem over the reals (Gibbs' inequality,
--                  Lin's JSD bound) whose float-lifted form is trusted modulo
--                  rounding; never discharged, only referenced.
--
-- The vacuous per-postulate `where _≥_/_≤_` relations of the original corpus
-- (POSTULATE-AUDIT "Additional concerns") are gone: all statements below use
-- the computational `InformationTheory.Foundations` order `_≤ᶠ_`.
{-# OPTIONS --without-K #-}

module InformationTheory.Axioms where

open import Data.Bool.Base using (T)
open import Data.Float using (Float; _+_; _*_; _÷_; -_; _≤ᵇ_; _≡ᵇ_; _<ᵇ_)
open import Data.Product using (_×_)
open import Relation.Binary.PropositionalEquality using (_≡_)

open import InformationTheory.Foundations

postulate
  -- log₂ is non-positive on [0,1]: 0 ≤ v ≤ 1 → log₂ v ≤ 0. True including
  -- v = 0 (log 0 = −∞ ≤ 0) and v = NaN (hypothesis is `T false`, i.e. ⊥).
  -- ECHIDNA:trust ffi-fact :: log₂-nonpos
  log₂-nonpos : (v : Float) → 0.0 ≤ᶠ v → v ≤ᶠ 1.0 → log₂ v ≤ᶠ 0.0

  -- Sign law of correctly-rounded multiplication: a ≥ 0 ∧ b ≤ 0 → −(a·b) ≥ 0.
  -- ECHIDNA:trust ffi-fact :: mul-sign
  -- a > 0 excludes 0·(−∞) = NaN.
  mul-sign : (a b : Float) → 0.0 <ᶠ a → b ≤ᶠ 0.0 → 0.0 ≤ᶠ - (a * b)

  -- Non-negative floats are closed under correctly-rounded addition.
  -- ECHIDNA:trust ffi-fact :: add-nonneg
  add-nonneg : (a b : Float) → 0.0 ≤ᶠ a → 0.0 ≤ᶠ b → 0.0 ≤ᶠ a + b

  -- Correctly-rounded addition is commutative as a bitwise operation (only
  -- associativity fails IEEE-754). Consumed by js-symmetric.
  -- ECHIDNA:trust ffi-fact :: add-comm
  add-comm : (a b : Float) → a + b ≡ b + a

  -- Gibbs' inequality lifted to float sums. Kept a conjecture on purpose:
  -- the real-analysis proof (log-sum inequality over reals) plus a rounding
  -- bridge is out of scope; see POSTULATE-AUDIT remediation Phase 2.
  -- ECHIDNA:trust conjecture :: kl-nonneg
  kl-nonneg : ∀ {n} (p q : Distribution n) → 0.0 ≤ᶠ kl-divergence p q

  -- Lin (1991): 0 ≤ JSD ≤ 1 in bits, lifted to float arithmetic. Same
  -- rationale as kl-nonneg.
  -- ECHIDNA:trust conjecture :: js-bounded
  js-bounded : ∀ {n} (p q : Distribution n) →
    0.0 ≤ᶠ jensen-shannon p q × jensen-shannon p q ≤ᶠ 1.0
