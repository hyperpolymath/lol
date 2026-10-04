#!/bin/sh
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell and Contributors
#
# audit-trust-base.sh — gate the quarantined Agda trust base (issue #4).
#
# Single implementation shared by .github/workflows/echidna-verify.yml, the
# `just prove-audit` recipe and the GitLab mirror job. Exits non-zero (with
# ::error:: annotations for Actions) when proofs/theories and
# proofs/trust-base.json disagree IN ANY DIRECTION, so a postulate can be
# neither smuggled in nor silently deleted from the audit.
#
# Checks:
#   1.  Every *.agda under proofs/theories is listed in the manifest as
#       either the quarantine module or a safe module (no unregistered
#       files, no stale entries).
#   2.  `postulate` may only occur in the quarantine file.
#   3.  Safe modules carry `--safe`; the quarantine file must NOT claim it
#       (Agda's --safe rejects postulates, so the claim would be dishonest
#       tooling rather than a sound split).
#   4.  Every postulate declaration carries an
#       `-- ECHIDNA:trust <class> :: <name>` tag directly above it; class is
#       in {ffi-fact, conjecture}; names are unique; and the whole
#       name:class set equals the manifest exactly.
#   5.  Per-class and total budgets match (source count == class_budget ==
#       total_budget == parsed manifest length — bidirectional).
#   6.  Regression guard for the 2026-04 soundness bug: no per-postulate
#       `where _≥_/_≤_ : Float → Float → Set`-style vacuous relations.
#   7.  Non-empty corpus (fail-closed, issue #4 note 2).
#
# Pure POSIX sh + awk + grep: no Python (banned estate-wide), no jq, works
# with whatever coreutils the runner/mirror carries.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
THEORIES="$ROOT/proofs/theories"
MANIFEST="$ROOT/proofs/trust-base.json"
TMP=$(mktemp -d 2>/dev/null || echo "/tmp/trustbase.$$")
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

ERRFILE="$TMP/errors"
: > "$ERRFILE"

err() {
    printf '::error::%s\n' "$1"
    printf '%s\n' "$1" >> "$ERRFILE"
}

if [ ! -f "$MANIFEST" ]; then
    err "missing manifest proofs/trust-base.json"
    printf 'trust-base audit: FAILED\n'
    exit 1
fi

# corpus file list (repo-relative), sorted
if [ -d "$THEORIES" ]; then
    find "$THEORIES" -name '*.agda' | sed "s|$ROOT/||" | LC_ALL=C sort > "$TMP/on-disk"
else
    : > "$TMP/on-disk"
fi
if [ ! -s "$TMP/on-disk" ]; then
    err "no .agda corpus under proofs/theories — a gate with nothing to check is no gate (fail-closed per issue #4 note 2)"
    printf 'trust-base audit: FAILED\n'
    exit 1
fi

# -- manifest parsing ---------------------------------------------------------
awk '
  function val(line, key,   re, s) {
    re = "\"" key "\": *\"[^\"]+\""
    if (match(line, re)) {
      s = substr(line, RSTART, RLENGTH)
      sub(/^"[^"]*": *"/, "", s)
      sub(/"$/, "", s)
      return s
    }
    return ""
  }
  /"quarantine":/       { print "Q\t" val($0, "quarantine"); next }
  /"safe_modules":/     { in_safe = 1; next }
  in_safe && /]/         { in_safe = 0; next }
  in_safe && /"/          { gsub(/[",]/,""); gsub(/^ +| +$/,""); print "S\t" $0; next }
  /"derived_modules":/  { in_derived = 1; next }
  in_derived && /]/      { in_derived = 0; next }
  in_derived && /"/       { gsub(/[",]/,""); gsub(/^ +| +$/,""); print "D\t" $0; next }
  /"name":/ && /"class":/ { print "A\t" val($0,"name") "\t" val($0,"class"); next }
  /"class_budget":/       { next }
  /"(ffi-fact|conjecture)":/ {
      line = $0; gsub(/[^0-9]/, "", line)
      key = $1; gsub(/[^a-zA-Z-]/,"",key)
      print "B\t" key "\t" line; next
  }
  /"total_budget":/       { line = $0; gsub(/[^0-9]/,"",line); print "T\t" line; next }
' "$MANIFEST" > "$TMP/manifest.tsv"

QUARANTINE=$(awk -F'\t' '$1=="Q"{print $2; exit}' "$TMP/manifest.tsv")
if [ -z "$QUARANTINE" ]; then
    err "manifest: no \"quarantine\" entry"
    QUARANTINE="NONE"
fi
awk -F'\t' '$1=="S"{print $2}' "$TMP/manifest.tsv" > "$TMP/safe-modules"
awk -F'\t' '$1=="D"{print $2}' "$TMP/manifest.tsv" > "$TMP/derived-modules"
awk -F'\t' '$1=="A"{print $2 " " $3}' "$TMP/manifest.tsv" | LC_ALL=C sort > "$TMP/manifest-axioms"
MANIFEST_TOTAL=$(awk -F'\t' '$1=="T"{print $2; exit}' "$TMP/manifest.tsv")
SAFE_COUNT=$(wc -l < "$TMP/safe-modules" | tr -d ' ')

# listed set ⇄ on-disk set
{ printf '%s\n' "$QUARANTINE"; cat "$TMP/safe-modules" "$TMP/derived-modules"; } | sed 's|^/||' | LC_ALL=C sort -u > "$TMP/listed"
unlisted=$(LC_ALL=C comm -23 "$TMP/on-disk" "$TMP/listed")
missing=$(LC_ALL=C comm -13 "$TMP/on-disk" "$TMP/listed")
if [ -n "$unlisted" ]; then
    err ".agda file(s) not registered in proofs/trust-base.json: $(printf '%s' "$unlisted" | tr '\n' ' ') — add to safe_modules/derived_modules (or extend the quarantine deliberately) in the same PR"
fi
if [ -n "$missing" ]; then
    err "manifest lists files that do not exist: $(printf '%s' "$missing" | tr '\n' ' ')"
fi

QPATH="$ROOT/$QUARANTINE"

# -- parse the quarantine source: state machine over postulate blocks --------
if [ -f "$QPATH" ]; then
    if grep -qE '\{-# OPTIONS[^#]*--safe' "$QPATH"; then
        err "$QUARANTINE: quarantine must not declare --safe (Agda rejects postulates under --safe)"
    fi
    awk -v qpath="$QUARANTINE" '
      # skip OPTIONS pragma line for the vacuity scan, track state otherwise
      { lines[NR] = $0 }
      END {
        inpost = 0
        for (i = 1; i <= NR; i++) {
          l = lines[i]
          if (l ~ /^[ \t]*postulate([ \t]|$)/) { inpost = 1; continue }
          if (l ~ /^[ \t]*$/) continue
          if (l ~ /^[ \t]*--/) continue
          if (inpost && l ~ /^[ \t]/) {
            if (match(l, /^[ \t][ \t]*[^ \t:]+[ \t]*:/)) {
              name = l
              sub(/^[ \t]+/, "", name); sub(/[ \t]*:.*$/, "", name)
              j = i - 1
              while (j >= 1 && lines[j] ~ /^[ \t]*$/) j--
              cls = ""
              if (j >= 1 && match(lines[j], /-- ECHIDNA:trust [^ ]+ :: [^ ]+/)) {
                tag = substr(lines[j], RSTART, RLENGTH)
                split(tag, parts, / +:: +/)
                cls = parts[1]; sub(/^-- ECHIDNA:trust +/, "", cls)
                tname = parts[2]
                if (tname != name)
                  printf "E %s:%d: tag names `%s` but declares `%s`\n", qpath, i, tname, name
              } else {
                printf "E %s:%d: postulate `%s` is not tagged — add `-- ECHIDNA:trust <class> :: %s` directly above it\n", qpath, i, name, name
                tname = name; cls = ""
              }
              if (cls != "" && cls != "ffi-fact" && cls != "conjecture")
                printf "E %s:%d: class `%s` not in {conjecture, ffi-fact}\n", qpath, i, cls
              if (seen[name]++)
                printf "E duplicate postulate `%s`\n", name
              if (cls != "") printf "A %s %s\n", name, cls
            }
            # vacuous where-relation regression (either shape: this line or the next)
            if (lines[i+1] ~ /^[ \t]+_[≥≤]_[ \t]*:/)
              printf "E %s:%d: `where _≥_/_≤_ : ...` — vacuous relation regression (2026-04 audit bug)\n", qpath, i + 1
            continue
          }
          if (inpost && l !~ /^[ \t]/) inpost = 0
        }
      }
    ' "$QPATH" > "$TMP/qout"
    grep '^E ' "$TMP/qout" | sed 's/^E //' | while IFS= read -r e; do err "$e"; done
    grep '^A ' "$TMP/qout" | sed 's/^A //' | LC_ALL=C sort > "$TMP/source-axioms"

    # explicit whole-file vacuity scan (independent of the state machine)
    if grep -nE '^[[:space:]]+_[≥≤]_[[:space:]]*:' "$QPATH" > "$TMP/vacuous" 2>/dev/null; then
        while IFS=: read -r ln _; do
            err "$QUARANTINE:$ln: vacuous where-relation (2026-04 audit regression)"
        done < "$TMP/vacuous"
    fi
else
    err "quarantine file missing: $QUARANTINE"
    : > "$TMP/source-axioms"
fi

# -- stray postulates outside the quarantine ---------------------------------
while IFS= read -r f; do
    [ "$f" = "$QUARANTINE" ] && continue
    if grep -nE '^[[:space:]]*postulate([[:space:]]|$)' "$ROOT/$f" > "$TMP/stray" 2>/dev/null; then
        while IFS=: read -r ln _; do
            err "$f:$ln: \`postulate\` outside the trust-base quarantine ($QUARANTINE)"
        done < "$TMP/stray"
    fi
done < "$TMP/on-disk"

# -- safe modules must claim --safe -------------------------------------------
while IFS= read -r name; do
    [ -f "$ROOT/$name" ] || continue
    if ! grep -qE '\{-# OPTIONS[^#]*--safe' "$ROOT/$name"; then
        err "$name: safe module must carry \`--safe\` in its OPTIONS pragma"
    fi
done < "$TMP/safe-modules"

# -- derived modules: postulate-free but axiom-consuming headers. Agda's
# flag-inheritance rule ("Importing module not using the --safe flag from a
# module which does", live CI evidence) makes a --safe top file that imports
# the quarantine a hard error, so those headers sit beside the quarantine,
# carry NO --safe claim, and are still census-checked for `postulate` above.
while IFS= read -r name; do
    [ -f "$ROOT/$name" ] || continue
    if grep -qE '\{-# OPTIONS[^#]*--safe' "$ROOT/$name"; then
        err "$name: registered as derived (axiom-importing) — it must NOT claim --safe; Agda would reject the import, so either discharge its axioms (then move it to safe_modules) or keep the honest flag"
    fi
done < "$TMP/derived-modules"

# -- set equality + budgets ----------------------------------------------------
cut -d' ' -f1 "$TMP/source-axioms" | LC_ALL=C sort -u > "$TMP/src-names"
cut -d' ' -f1 "$TMP/manifest-axioms" | LC_ALL=C sort -u > "$TMP/man-names"
only_src=$(LC_ALL=C comm -23 "$TMP/src-names" "$TMP/man-names")
only_man=$(LC_ALL=C comm -13 "$TMP/src-names" "$TMP/man-names")
if [ -n "$only_src" ]; then err "postulates not in manifest: $(printf '%s' "$only_src" | tr '\n' ' ')"; fi
if [ -n "$only_man" ]; then err "manifest entries absent from source: $(printf '%s' "$only_man" | tr '\n' ' ')"; fi
mismatch=$(LC_ALL=C join -j 1 "$TMP/source-axioms" "$TMP/manifest-axioms" | awk '{if ($2 != $3) print $1 ": source=" $2 " manifest=" $3}')
if [ -n "$mismatch" ]; then printf '%s\n' "$mismatch" | while IFS= read -r m; do err "$m class mismatch"; done; fi

SRC_TOTAL=$(wc -l < "$TMP/source-axioms" | tr -d ' ')
MAN_TOTAL=$(wc -l < "$TMP/manifest-axioms" | tr -d ' ')
if [ "$SRC_TOTAL" != "$MAN_TOTAL" ]; then
    err "axiom count: source has $SRC_TOTAL, manifest lists $MAN_TOTAL (parse drift?)"
fi
for cls in ffi-fact conjecture; do
    cap=$(awk -F'\t' -v c="$cls" '$1=="B" && $2==c {print $3; exit}' "$TMP/manifest.tsv")
    got=$(cut -d' ' -f2 "$TMP/source-axioms" | grep -c "^$cls$" || true)
    if [ -n "$cap" ] && [ "$got" != "$cap" ]; then
        err "class \`$cls\`: source has $got, manifest budget is $cap — adjust proofs/trust-base.json AND POSTULATE-AUDIT.adoc together"
    fi
done
if [ -n "$MANIFEST_TOTAL" ] && [ "$SRC_TOTAL" != "$MANIFEST_TOTAL" ]; then
    err "total postulates: source has $SRC_TOTAL, budget is $MANIFEST_TOTAL"
fi

if [ -s "$ERRFILE" ]; then
    printf 'trust-base audit: FAILED (%s problem(s))\n' "$(wc -l < "$ERRFILE" | tr -d ' ')"
    exit 1
fi

printf 'trust-base audit: OK — %s postulate(s) in quarantine (%s), %s safe module(s), %s .agda file(s) total\n' \
    "$SRC_TOTAL" \
    "$(cut -d' ' -f2 "$TMP/source-axioms" | LC_ALL=C sort | uniq -c | awk '{printf "%s=%s ", $2, $1}')" \
    "$SAFE_COUNT" \
    "$(wc -l < "$TMP/on-disk" | tr -d ' ')"
