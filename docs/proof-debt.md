<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell and Contributors

docs/proof-debt.md — estate Trusted-Base Reduction Policy ledger for this
repo (hyperpolymath/standards docs/TRUSTED-BASE-REDUCTION-POLICY.adoc).
Enforced by `standards/scripts/check-trusted-base.sh` via the governance
workflow; every `postulate` in `proofs/**/*.agda` must appear here or carry
an inline `TRUSTED:`/`AXIOM:` leading comment. This repo does both: the
inline blocks are in `proofs/theories/InformationTheory/Axioms.agda`, and
this document is the ledger.

Machine-readable counterpart (name/class/budget, gated by
`scripts/audit-trust-base.sh`): `proofs/trust-base.json`.
Human prose rationale: `proofs/POSTULATE-AUDIT.adoc`.
-->

# Proof debt

Corpus: `proofs/theories/` (Agda). Single quarantined trust base:
`proofs/theories/InformationTheory/Axioms.agda`. All other modules compile
with `agda --safe`, which itself rejects `postulate` — so this ledger and
the file it describes can never silently diverge from what the checker
accepts (the CI job in `.github/workflows/echidna-verify.yml` enforces
set-equality against `proofs/trust-base.json` in both directions).

## (a) Discharged in this repo

- `entropy-nonnegative` (pre-2026 `information_theory.agda`, 2026-04 audit
  Phase 2 #2) — **discharged 2026-10-04** as `InformationTheory.entropy-nonneg`:
  proven by induction over the vector sum from the guarded entry function;
  see PR #18.
- `js-symmetric` (audit Phase 2 #1) — **discharged 2026-10-04** as
  `InformationTheory.js-symmetric`: midpoint swap via `add-comm`, no
  associativity required; see PR #18.
- `log₂`, `_*f_`, `_+f_`, `negateF`, `_/f_` (the 2024 baseline's five "FFI
  axiom" float ops) — **discharged 2026-10-04** by definition: they are
  re-exports of `Agda.Builtin.Float` primitives through `Data.Float`, not
  postulates. A re-export is not a trust assumption.

## (b) Budgeted — tested with refutation budget

- (none)

## (c) Necessary axiom

- `proofs/theories/InformationTheory/Axioms.agda` — `plogp-nonneg`
  - **Kind**: IEEE-754 property of the guarded entropy term (post-log
    multiplication non-negativity on [0,1]); not derivable in intensional
    type theory over opaque float primitives.
  - **Justification**: true of correctly-rounded IEEE `log`, `*`, `-`; the
    guard (`0.0 <ᵇ v` in `Foundations.plogp`) makes the out-of-domain side
    evaluate to exactly `0.0`, so the statement is non-refutable by
    evaluation (no `0·(−∞) = NaN` witness — see PR #18 review, where an
    earlier unguarded formulation was caught refutable at v = 0).
  - **Citation**: equivalent real-analysis statement in
    `agda-real`/Coq stdlibs; float-side sign law: IEEE-754 §6.3 exact
    rounding of operations preserving operand sign.
- `proofs/theories/InformationTheory/Axioms.agda` — `add-nonneg`
  - **Kind**: closure of non-negative floats (including +∞) under
    correctly-rounded addition; NaN excluded by the hypotheses themselves.
  - **Justification / Citation**: IEEE-754 §6.3 + §7.2; no associativity
    is assumed anywhere (only the binary law is postulated).
- `proofs/theories/InformationTheory/Axioms.agda` — `add-comm`
  - **Kind**: bitwise commutativity of correctly-rounded float addition.
  - **Justification**: holds for every IEEE-754 operand pair including
    NaN payload propagation and the ±0 corners under round-to-nearest;
    used by `js-symmetric` only.
  - **Citation**: IEEE-754-2019 §6.3 (each operation returns the rounded
    exact result, which is symmetric in its two operands for `+`).

## (d) DEBT — actively to be closed

- `proofs/theories/InformationTheory/Axioms.agda` — `kl-nonneg` (class
  `conjecture`)
  - **Owner**: @hyperpolymath
  - **Plan**: discharge over a reals model (agda-real or an internal ℝ
    formalisation): Gibbs via the log-sum inequality, then bridge to float
    with explicit rounding-tolerance lemmas against `Distribution`'s
    `normalised : sumF values ≡ 1.0` (the bridge is where the corpus
    should get *stronger*: as stated it is true modulo ≤ 1 ulp of slack;
    an exact-float version would need compensated summation in `Foundations.sumF`).
  - **Deadline**: 2027-03-31 (estate proof-debt epic
    hyperpolymath/standards#124 sweep boundary)
- `proofs/theories/InformationTheory/Axioms.agda` — `js-bounded` (class
  `conjecture`)
  - **Owner**: @hyperpolymath
  - **Plan**: Lin (1991) upper bound 1 bit + non-negativity via
    `kl-nonneg` after that discharges (JSD is an average of two KLs); the
    upper-bound half additionally needs the monotonicity bridge, same
    rounding machinery as `kl-nonneg`.
  - **Deadline**: 2027-03-31 (inherits from `kl-nonneg` above)
