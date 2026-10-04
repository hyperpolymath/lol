#!/usr/bin/env python3
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell and Contributors
"""
audit-trust-base.py — gate the quarantined Agda trust base (issue #4).

Single implementation shared by .github/workflows/echidna-verify.yml and
`just prove-audit`. Exits non-zero (with ::error:: annotations for Actions)
when the corpus and proofs/trust-base.json disagree in ANY direction, so a
postulate can be neither smuggled in nor silently deleted from the audit.

Checks:
  1.  Every *.agda under proofs/theories is listed in the manifest as either
      the quarantine module or a safe module (no unregistered files).
  2.  `postulate` may only occur in the quarantine file.
  3.  Safe modules carry `--safe`; the quarantine file must NOT claim it
      (Agda's --safe rejects postulates, so the claim would be dishonest
      tooling rather than a sound split).
  4.  Every postulate declaration is preceded (within one comment line) by an
      `-- ECHIDNA:trust <class> :: <name>` tag whose name matches the
      declaration, class is in {ffi-fact, conjecture}, and the whole set
      (names, per-class counts, total) equals the manifest exactly.
  5.  Regression guard for the 2026-04 soundness bug: no per-postulate
      `where _≥_/_≤_ : Float → Float → Set`-style vacuous relation clauses.
  6.  Non-empty corpus (fail-closed, issue #4 note 2).
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
THEORIES = REPO_ROOT / "proofs" / "theories"
MANIFEST = REPO_ROOT / "proofs" / "trust-base.json"
ALLOWED_CLASSES = {"ffi-fact", "conjecture"}

POSTULATE_RE = re.compile(r"^\s*postulate(\s|$)")
DECL_RE = re.compile(r"^\s+(\S+)\s+:")
TAG_RE = re.compile(r"^\s*--\s*ECHIDNA:trust\s+(\S+)\s+::\s+(\S+)\s*$")
VACUOUS_RE = re.compile(r"^\s+_[≥≤]_\s*:")

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)
    print(f"::error::{msg}")


def rel(p: Path) -> str:
    return p.relative_to(REPO_ROOT).as_posix()


def main() -> int:
    if not MANIFEST.is_file():
        err(f"missing manifest {rel(MANIFEST)}")
        return 1
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    agda_files = sorted(THEORIES.rglob("*.agda")) if THEORIES.is_dir() else []
    if not agda_files:
        err("no .agda corpus under proofs/theories — a gate with nothing to "
            "check is no gate (fail-closed per issue #4 note 2)")
        return 1

    quarantine = manifest.get("quarantine")
    safe_modules = manifest.get("safe_modules", [])
    expected = manifest.get("axioms", [])
    class_budget = manifest.get("class_budget", {})
    total_budget = manifest.get("total_budget")

    listed = set(map(str, [quarantine] + list(safe_modules)))
    on_disk = {rel(p) for p in agda_files}
    unlisted = on_disk - listed
    missing = listed - on_disk
    if unlisted:
        err(f".agda file(s) not registered in {rel(MANIFEST)}: "
            f"{sorted(unlisted)} — add to safe_modules (or extend the "
            f"quarantine deliberately) in the same PR")
    if missing:
        err(f"manifest lists files that do not exist: {sorted(missing)}")

    qpath = REPO_ROOT / quarantine if quarantine else None
    if qpath and qpath.is_file():
        qtext = qpath.read_text(encoding="utf-8")
        if "--safe" in (re.search(r"\{-# OPTIONS[^\n]*", qtext).group(0)
                        if re.search(r"\{-# OPTIONS[^\n]*", qtext) else ""):
            err(f"{rel(qpath)}: quarantine must not declare --safe "
                "(Agda rejects postulates under --safe)")

        # --tag → declaration pairing, and per-declaration postulate-block walk
        lines = qtext.splitlines()
        found: dict[str, str] = {}
        in_postulate = False
        for i, line in enumerate(lines):
            if POSTULATE_RE.match(line):
                in_postulate = True
                continue
            if line.strip() == "" or line.lstrip().startswith("--"):
                continue
            if in_postulate and (line.startswith((" ", "\t"))):
                m = DECL_RE.match(line)
                if m:
                    name = m.group(1)
                    # find tag: nearest preceding non-blank comment line pair
                    j = i - 1
                    while j >= 0 and lines[j].strip() == "":
                        j -= 1
                    tag = TAG_RE.match(lines[j]) if j >= 0 else None
                    if not tag:
                        err(f"{rel(qpath)}:{i + 1}: postulate `{name}` is not "
                            f"tagged — add `-- ECHIDNA:trust <class> :: {name}` "
                            f"directly above it")
                    else:
                        cls, tname = tag.group(1), tag.group(2)
                        if tname != name:
                            err(f"{rel(qpath)}:{i + 1}: tag names `{tname}` "
                                f"but declares `{name}`")
                        if cls not in ALLOWED_CLASSES:
                            err(f"{rel(qpath)}:{i + 1}: class `{cls}` not in "
                                f"{sorted(ALLOWED_CLASSES)}")
                        if name in found:
                            err(f"duplicate postulate `{name}`")
                        found[name] = cls
                    if VACUOUS_RE.match(lines[i + 1] if i + 1 < len(lines) else ""):
                        err(f"{rel(qpath)}:{i + 2}: `where _≥_/_≤_ : ...` — "
                            f"vacuous relation regression (2026-04 audit bug)")
                continue
            if in_postulate and not line.startswith((" ", "\t")):
                in_postulate = False
        for i, line in enumerate(lines):
            if VACUOUS_RE.match(line):
                err(f"{rel(qpath)}:{i + 1}: vacuous where-relation "
                    f"(2026-04 audit regression)")
    else:
        err(f"quarantine file missing: {quarantine}")

    # postulate keyword may not appear outside the quarantine
    for p in agda_files:
        if qpath and p == qpath:
            continue
        for n, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            if re.match(r"^\s*postulate(\s|$)", line):
                err(f"{rel(p)}:{n}: `postulate` outside the trust-base "
                    f"quarantine ({quarantine})")

    # safe modules must claim --safe
    for name in safe_modules:
        spath = REPO_ROOT / name
        if not spath.is_file():
            continue  # already reported via `missing`
        s = spath.read_text(encoding="utf-8")
        if "--safe" not in s:
            err(f"{name}: safe module must carry `--safe` in its OPTIONS pragma")

    # manifest ⇄ source set equality
    exp = {a["name"]: a["class"] for a in expected}
    if set(exp) != set(found):
        only_src = sorted(set(found) - set(exp))
        only_man = sorted(set(exp) - set(found))
        if only_src:
            err(f"postulates not in manifest: {only_src}")
        if only_man:
            err(f"manifest entries absent from source: {only_man}")
    for name in sorted(set(exp) & set(found)):
        if exp[name] != found[name]:
            err(f"`{name}`: class `{found[name]}` in source but "
                f"`{exp[name]}` in manifest")
    per_class: dict[str, int] = {}
    for cls in found.values():
        per_class[cls] = per_class.get(cls, 0) + 1
    for cls, cap in class_budget.items():
        if per_class.get(cls, 0) != cap:
            err(f"class `{cls}`: source has {per_class.get(cls, 0)}, manifest "
                f"budget is {cap} — adjust proofs/trust-base.json AND "
                f"POSTULATE-AUDIT.adoc together")
    if total_budget is not None and len(found) != total_budget:
        err(f"total postulates: source has {len(found)}, budget is "
            f"{total_budget}")

    if errors:
        print(f"trust-base audit: FAILED ({len(errors)} problem(s))")
        return 1
    print(f"trust-base audit: OK — {len(found)} postulate(s) in quarantine "
          f"({', '.join(f'{c}={n}' for c, n in sorted(per_class.items()))}), "
          f"{len(safe_modules)} safe module(s), {len(agda_files)} .agda file(s) total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
