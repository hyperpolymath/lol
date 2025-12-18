# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via [GitHub Security Advisories](https://github.com/Hyperpolymath/1000Langs/security/advisories/new).

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting)
- Full paths of source file(s) related to the issue
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Preferred Languages

We prefer all communications to be in English.

## Security Measures

This project implements:

- SHA-pinned GitHub Actions for supply chain security
- CodeQL static analysis for JavaScript/TypeScript
- OSSF Scorecard security assessment
- TruffleHog secret scanning
- Dependency vulnerability monitoring via Dependabot
- RFC 9116 security.txt compliance
