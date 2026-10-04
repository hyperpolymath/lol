#!/bin/sh
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell and Contributors
#
# prove-agda.sh — type-check proofs/theories exactly as
# .github/workflows/echidna-verify.yml does (issue #4). Used by that
# workflow, by `just prove-agda`/`just prove-check-all`, and by the GitLab
# mirror job, so the three surfaces cannot drift.
#
# Layered trust: modules whose OPTIONS pragma declares `--safe` are checked
# with `--safe --without-K` (Agda then rejects any `postulate`); the
# quarantined trust base (proofs/theories/InformationTheory/Axioms.agda) is
# checked with `--without-K` only. The pragma is the source of truth;
# scripts/audit-trust-base.sh separately enforces WHICH file may carry which
# pragma and which may carry postulates.
#
# Fail-closed on: missing agda, missing/unusable stdlib, empty corpus, any
# module failing to type-check.
#
# Env overrides: AGDA (binary), AGDA_STDLIB_DIR (source tree of stdlib to
# pass via -i), AGDA_COMPILE_DIR (where .agdai go; default ./agda-compile-dir).

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

AGDA=${AGDA:-agda}
COMPILE_DIR=${AGDA_COMPILE_DIR:-"$ROOT/agda-compile-dir"}
THEORY_DIR=proofs/theories
fail=0

command -v "$AGDA" >/dev/null 2>&1 || {
    echo "::error::agda not found on PATH — install it (CI: apt-get install -y agda agda-stdlib; local: the same, or nix-shell -p agda agdaPackages.stdlib)"
    exit 1
}
"$AGDA" --version 2>&1 || echo "note: agda --version failed (continuing — probe will assess)"

# -- locate the stdlib ---------------------------------------------------------
# Ubuntu/Debian's agda-stdlib installs pre-compiled sources *loose* under
# /usr/share/agda-stdlib (there is no .agda-lib file in that package layout —
# the standards-era workflow assumed a library manifest and would have found
# nothing, silently). Register by include path when sources are loose, and by
# ~/.agda/libraries only when an .agda-lib manifest exists.
STDLIB_DIR=${AGDA_STDLIB_DIR:-}
if [ -z "$STDLIB_DIR" ]; then
    for d in /usr/share/agda-stdlib /usr/share/agda/std-lib /usr/local/share/agda-stdlib; do
        if [ -f "$d/Data/Nat.agda" ] || [ -f "$d/extra/AGDA-stdlib-VERSION" ]; then
            STDLIB_DIR=$d
            break
        fi
        lib=$(find "$d" -maxdepth 3 -name '*.agda-lib' 2>/dev/null | head -1 || true)
        if [ -n "$lib" ]; then
            mkdir -p "$HOME/.agda/libraries"
            touch "$HOME/.agda/libraries/estate-stdlib" "$HOME/.agda/defaults"
            grep -qxF "$lib" "$HOME/.agda/libraries/estate-stdlib" || echo "$lib" >> "$HOME/.agda/libraries/estate-stdlib"
            name=$(awk '$1=="name:"{print $2; exit}' "$lib")
            if [ -n "$name" ] && ! grep -qxF "$name" "$HOME/.agda/defaults"; then
                echo "$name" >> "$HOME/.agda/defaults"
            fi
            echo "Registered stdlib library: $lib (as ${name:-unknown})"
            STDLIB_DIR=""
            break
        fi
    done
fi
if [ -n "$STDLIB_DIR" ]; then
    echo "Using stdlib sources from: $STDLIB_DIR ($(find "$STDLIB_DIR" -name '*.agda' | wc -l) modules)"
fi

mkdir -p "$COMPILE_DIR"

# -- probe: prove stdlib visibility BEFORE checking anything -------------------
# The standards-side job skipped its steps and still "passed" once the corpus
# moved; a check that cannot see its toolchain must be red, not green-skipped.
PROBE_DIR=$(mktemp -d 2>/dev/null || echo "$COMPILE_DIR/probe")
mkdir -p "$PROBE_DIR"
cat > "$PROBE_DIR/Probe.agda" <<'EOF'
module Probe where
open import Data.Nat using (ℕ)
open import Data.Vec using (Vec)
open import Data.Float using (Float)
EOF
# `set -e` must not swallow the diagnosis: every agda invocation is funnelled
# through run_agda, which tees output to a per-call file and, on failure,
# re-emits the first lines as an annotation (workflow commands reach the
# checks API; raw logs are not always retrievable).
run_agda() {
    _out="$PROBE_DIR/agda.out"
    _rc=0
    "$AGDA" "$@" >"$_out" 2>&1 || _rc=$?
    sed 's/^/    /' "$_out"
    if [ $_rc -ne 0 ]; then
        _ann=$(head -14 "$_out" | cut -c1-220 | sed 's/%/%25/g; s/::/%3A%3A/g' | awk '{printf "%s%%0A", $0}')
        echo "::error::agda exit $_rc: ${_ann}"
    fi
    return $_rc
}
PROBE_OK=0
if [ -n "$STDLIB_DIR" ]; then
    if run_agda --safe --compile-dir "$COMPILE_DIR" -i "$STDLIB_DIR" -i "$PROBE_DIR" "$PROBE_DIR/Probe.agda"; then
        PROBE_OK=1
    else
        # Older packaged .agdai trees can reject a foreign --compile-dir
        # (interface staleness -> attempted write next to root-owned sources).
        # Retry without it before declaring the toolchain unusable.
        echo "note: probe failed with --compile-dir; retrying without (source-tree .agdai layout)"
        if run_agda --safe -i "$STDLIB_DIR" -i "$PROBE_DIR" "$PROBE_DIR/Probe.agda"; then
            PROBE_OK=1
            COMPILE_DIR=
            echo "note: continuing without --compile-dir"
        fi
    fi
else
    if run_agda --safe --compile-dir "$COMPILE_DIR" -i "$PROBE_DIR" "$PROBE_DIR/Probe.agda"; then
        PROBE_OK=1
    else
        run_agda --safe -i "$PROBE_DIR" "$PROBE_DIR/Probe.agda" && { PROBE_OK=1; COMPILE_DIR=; }
    fi
fi
if [ "$PROBE_OK" -ne 0 ]; then
    echo "stdlib probe OK (Data.Nat / Data.Vec / Data.Float resolve under --safe)"
else
    echo "::error::stdlib probe failed — Agda cannot see the standard library (STDLIB_DIR='${STDLIB_DIR:-<none>}'); refusing to run the corpus against a broken toolchain"
    exit 1
fi

# -- corpus ---------------------------------------------------------------------
FILES=$(find "$THEORY_DIR" -name '*.agda' | LC_ALL=C sort)
if [ -z "$FILES" ]; then
    echo "::error::no .agda files under $THEORY_DIR — refusing to report success with an empty corpus (issue #4 note 2)"
    exit 1
fi

for f in $FILES; do
    # Pragma-scoped match only: a comment mentioning --safe must not flip a
    # file into safe mode (the Axioms header discusses --safe at length).
    if grep -qE '\{-# OPTIONS[^#]*--safe' "$f"; then
        flags="--safe --without-K"
    else
        flags="--without-K"
        echo "note: $f is the quarantined trust base (compiled without --safe by design)"
    fi
    echo "--- checking $f ($flags) ---"
    if [ -n "$STDLIB_DIR" ]; then
        inc="-i $STDLIB_DIR -i $THEORY_DIR"
    else
        inc="-i $THEORY_DIR"
    fi
    if [ -n "$COMPILE_DIR" ]; then
        cdir="--compile-dir $COMPILE_DIR"
    else
        cdir=
    fi
    if ! run_agda $flags $cdir $inc "$f"; then
        echo "::error::agda type-check FAILED for $f"
        fail=1
    fi
done

rm -rf "$PROBE_DIR"

if [ "$fail" -ne 0 ]; then
    exit 1
fi
echo "All Agda proofs type-checked cleanly under the enforced flags."
