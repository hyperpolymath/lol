-- SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
-- SPDX-FileCopyrightText: 2024-2026 Ehsaneddin Asgari and Contributors
--
-- Information Theory — quarantined trust base
-- ============================================
-- This is the ONLY module in the corpus allowed to contain `postulate`.
-- It is deliberately compiled WITHOUT `--safe`: `--safe` rejects `postulate`
-- outright (Agda test SafeFlagPostulate), so the quarantine is what lets an
-- honest trust base coexist with a hard `--safe` gate on everything else.
-- Enforced by .github/workflows/echidna-verify.yml (issue #4):
--
--   * `grep postulate` outside this file is a hard CI failure;
--   * every postulate declaration carries an `ECHIDNA:trust <class> :: <name>`
--     tag on the line above it;
--   * names, classes and counts must match proofs/trust-base.json exactly
--     (see scripts/audit-trust-base.sh and proofs/POSTULATE-AUDIT.adoc);
--   * each `postulate` keyword block is preceded, with no blank line in
--     between, by a leading comment containing `AXIOM:` or `TRUSTED:` —
--     the estate-wide marker consumed by standards' check-trusted-base.sh
--     (Trusted-Base Reduction Policy); and
--   * every entry is mirrored in docs/proof-debt.md.
--
-- Classes:
--   ffi-fact   — a true property of correctly-rounded IEEE-754 arithmetic
--                that Agda cannot derive from its opaque Float primitives.
--   conjecture — a classical theorem over the reals whose float-lifted form
--                is trusted modulo rounding; never used by any proven
--                result, only referenced (budgeted debt, deadline in
--                docs/proof-debt.md).
--
-- Design invariant (the PR #18 review lesson): no axiom may be refutable by
-- evaluation. Statements therefore talk about the *guarded* terms from
-- Foundations (`plogp` is NaN-safe by construction), never about raw
-- `v * log₂ v` under non-strict hypotheses — an earlier draft postulating
-- `0 ≤ a → b ≤ 0 → 0 ≤ −(a·b)` was refutable at a = 0, b = −∞ (0·(−∞) =
-- NaN), which would have inhabited ⊥.
{-# OPTIONS --without-K #-}

module InformationTheory.Axioms where

open import Data.Float using (Float; _+_)
open import Data.Product using (_×_)
open import Relation.Binary.PropositionalEquality using (_≡_)

open import InformationTheory.Foundations

-- Necessary foundational axioms (Trusted-Base Reduction Policy §c): true
-- facts about correctly-rounded hardware arithmetic, not proof debt. They
-- are what make the per-entry and algebraic theorems in InformationTheory
-- checkable without a full real-analysis model of the reals.
--
-- AXIOM: ffi-facts — IEEE-754 properties of the runtime float primitives,
-- unverifiable in intensional type theory over opaque builtins. Listed with
-- rationale in proofs/POSTULATE-AUDIT.adoc and docs/proof-debt.md.
postulate
  -- −p·log₂ p (the guarded `InformationTheory.Foundations.plogp`) is
  -- non-negative on [0, 1]: the per-entry heart of entropy-nonneg. True
  -- including the guarded out-of-domain side (which returns exactly 0.0)
  -- and at p = 1 (result −0.0, and 0 ≤ᵇ −0.0 computes to true).
  -- ECHIDNA:trust ffi-fact :: plogp-nonneg
  plogp-nonneg : (v : Float) → 0.0 ≤ᶠ v → v ≤ᶠ 1.0 → 0.0 ≤ᶠ plogp v

  -- Non-negative floats are closed under correctly-rounded addition
  -- (including +∞: NaN inputs fail the hypotheses, so no side condition).
  -- ECHIDNA:trust ffi-fact :: add-nonneg
  add-nonneg : (a b : Float) → 0.0 ≤ᶠ a → 0.0 ≤ᶠ b → 0.0 ≤ᶠ a + b

  -- Correctly-rounded addition is commutative as a *bitwise* operation (only
  -- associativity fails IEEE-754; under round-to-nearest, x + y and y + x
  -- produce the identical value, including NaN payload propagation and the
  -- ±0 corner: +0 + −0 = +0 = −0 + +0). Consumed by js-symmetric.
  -- ECHIDNA:trust ffi-fact :: add-comm
  add-comm : (a b : Float) → a + b ≡ b + a

-- Budgeted, dated proof debt (Trusted-Base Reduction Policy §d): classical
-- results over the reals (Gibbs' inequality via the log-sum inequality;
-- Lin 1991 JSD bounds) whose float-lifted forms need a rounding bridge on
-- top of a reals model. `Distribution`'s hypotheses (entries in [0, 1] via
-- the comparison primitives, `normalised` float sum) keep these statements
-- true-as-stated-modulo-rounding rather than vacuous or refutable — the
-- 2026-04 corpus failed on exactly this axis. See docs/proof-debt.md §(d).
--
-- TRUSTED: enumerated as budgeted debt, owner + deadline in
-- docs/proof-debt.md; discharging either axiom must land with the matching
-- manifest and audit updates (scripts/audit-trust-base.sh fails otherwise).
postulate
  -- ECHIDNA:trust conjecture :: kl-nonneg
  kl-nonneg : ∀ {n} (p q : Distribution n) → 0.0 ≤ᶠ kl-divergence p q

  -- ECHIDNA:trust conjecture :: js-bounded
  js-bounded : ∀ {n} (p q : Distribution n) →
    0.0 ≤ᶠ jensen-shannon p q × jensen-shannon p q ≤ᶠ 1.0
