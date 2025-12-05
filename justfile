# SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
# SPDX-FileCopyrightText: 2024-2025 Ehsaneddin Asgari and Contributors
#
# 1000Langs Justfile - RSR Gold Compliant
# ========================================
# Comprehensive task automation for the super-parallel corpus crawler

set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments := true
set dotenv-load := true

# Default recipe - show help
default: help

# ============================================================================
# HELP & DOCUMENTATION
# ============================================================================

# Show all available recipes with descriptions
help:
    @just --list --unsorted

# Show detailed help for a specific recipe
help-recipe RECIPE:
    @just --show {{RECIPE}}

# Generate documentation for all recipes
docs:
    @echo "Generating recipe documentation..."
    @just --list --list-heading $'# Available Recipes\n\n' --list-prefix '- ' > docs/RECIPES.md

# ============================================================================
# DEVELOPMENT ENVIRONMENT
# ============================================================================

# Enter Nix development shell
shell:
    nix develop

# Install all dependencies
install:
    npm install

# Update all dependencies
update:
    npm update
    nix flake update

# Clean all build artifacts
clean:
    npm run clean
    rm -rf node_modules/.cache
    rm -rf coverage
    rm -rf .vitest

# Deep clean including node_modules
clean-all: clean
    rm -rf node_modules
    rm -rf .rescript

# ============================================================================
# BUILD & COMPILE
# ============================================================================

# Build ReScript to JavaScript
build:
    npm run build

# Build with watch mode
watch:
    npm run watch

# Build for production (optimized)
build-prod:
    NODE_ENV=production npm run build

# Type check without building
typecheck:
    npx rescript build -warn-error

# Build documentation
build-docs:
    asciidoctor docs/*.adoc -D docs/html

# ============================================================================
# TESTING
# ============================================================================

# Run all tests
test:
    npm test

# Run tests with watch mode
test-watch:
    npm run test:watch

# Run tests with coverage
test-coverage:
    npm run test:coverage

# Run specific test file
test-file FILE:
    npm test -- {{FILE}}

# Run tests matching pattern
test-grep PATTERN:
    npm test -- -t "{{PATTERN}}"

# Run unit tests only
test-unit:
    npm test -- test/unit

# Run integration tests only
test-integration:
    npm test -- test/integration

# Run proof verification tests
test-proofs:
    npm test -- test/proofs

# ============================================================================
# CODE QUALITY
# ============================================================================

# Run linter
lint:
    npm run lint

# Fix linting issues automatically
lint-fix:
    npm run lint:fix

# Format code
format:
    npm run format

# Check formatting without changes
format-check:
    npx biome format --check .

# Run all quality checks
check: lint format-check typecheck test

# Pre-commit checks
pre-commit: lint-fix format check

# ============================================================================
# PROOFS & VERIFICATION
# ============================================================================

# Run Echidna proof verification
prove:
    @echo "Running Echidna proof verification..."
    cd proofs && echidna verify

# Check specific proof
prove-check PROOF:
    cd proofs && echidna check {{PROOF}}

# Generate proof obligations
prove-gen:
    @echo "Generating proof obligations from specifications..."
    cd proofs && echidna generate

# Validate proof dependencies
prove-deps:
    cd proofs && echidna deps --check

# ============================================================================
# CORPUS OPERATIONS
# ============================================================================

# Crawl all sources
crawl-all:
    @echo "Crawling all Bible corpus sources..."
    node dist/Lang1000.res.mjs crawl --all

# Crawl specific source
crawl SOURCE:
    node dist/Lang1000.res.mjs crawl --source {{SOURCE}}

# List available languages
languages:
    node dist/Lang1000.res.mjs languages --list

# Show language statistics
language-stats:
    node dist/Lang1000.res.mjs stats --languages

# Build parallel corpus
corpus-build:
    node dist/Lang1000.res.mjs corpus --build

# Validate corpus integrity
corpus-validate:
    node dist/Lang1000.res.mjs corpus --validate

# Export corpus to format
corpus-export FORMAT="json":
    node dist/Lang1000.res.mjs corpus --export {{FORMAT}}

# ============================================================================
# CONTAINER OPERATIONS (PODMAN)
# ============================================================================

# Build container image
container-build:
    podman build -t 1000langs:latest -f Containerfile .

# Build container without cache
container-build-nocache:
    podman build --no-cache -t 1000langs:latest -f Containerfile .

# Run container
container-run:
    podman run --rm -it 1000langs:latest

# Run container with volume mount
container-dev:
    podman run --rm -it -v .:/app:Z 1000langs:latest

# Push container to registry
container-push REGISTRY:
    podman push 1000langs:latest {{REGISTRY}}/1000langs:latest

# List container images
container-list:
    podman images | grep 1000langs

# Clean container images
container-clean:
    podman rmi 1000langs:latest || true

# ============================================================================
# RSR COMPLIANCE
# ============================================================================

# Run full RSR audit
rsr-audit:
    ./scripts/rsr-audit.sh . text

# Run RSR audit with JSON output
rsr-audit-json:
    ./scripts/rsr-audit.sh . json

# Run RSR audit with HTML report
rsr-audit-html:
    ./scripts/rsr-audit.sh . html > reports/rsr-audit.html

# Check compliance level
rsr-level:
    @./scripts/rsr-audit.sh . json | jq -r '.compliance_level'

# Validate SPDX headers
spdx-check:
    @echo "Checking SPDX license headers..."
    @find src test -name "*.res" -exec grep -L "SPDX-License-Identifier" {} \; | \
        xargs -I {} echo "Missing SPDX header: {}"

# Add SPDX headers to files
spdx-fix:
    @echo "Adding SPDX headers to files..."
    ./scripts/add-spdx-headers.sh

# ============================================================================
# RELEASE & VERSIONING
# ============================================================================

# Show current version
version:
    @jq -r '.version' package.json

# Bump patch version
bump-patch:
    npm version patch --no-git-tag-version

# Bump minor version
bump-minor:
    npm version minor --no-git-tag-version

# Bump major version
bump-major:
    npm version major --no-git-tag-version

# Create release
release VERSION:
    @echo "Creating release v{{VERSION}}..."
    npm version {{VERSION}} -m "Release v{{VERSION}}"
    git push origin main --tags

# Generate changelog
changelog:
    @echo "Generating CHANGELOG.md..."
    git log --pretty=format:"- %s (%h)" --no-merges > CHANGELOG.md.tmp
    cat CHANGELOG.md.tmp >> CHANGELOG.md
    rm CHANGELOG.md.tmp

# ============================================================================
# NICKEL CONFIGURATION
# ============================================================================

# Validate Nickel configuration
nickel-check:
    nickel eval config/main.ncl

# Export Nickel to JSON
nickel-export:
    nickel export config/main.ncl > config/config.json

# Show resolved configuration
nickel-show:
    nickel eval config/main.ncl | jq .

# ============================================================================
# CI/CD HELPERS
# ============================================================================

# Setup CI environment
ci-setup:
    npm ci

# Run CI checks
ci-check: ci-setup check

# Build for CI
ci-build: ci-setup build-prod test-coverage

# Deploy artifacts
ci-deploy:
    @echo "Deploying artifacts..."

# ============================================================================
# DEVELOPMENT UTILITIES
# ============================================================================

# Start development server
dev: watch

# Open project in editor
edit:
    $EDITOR .

# Show project structure
tree:
    @tree -I 'node_modules|.git|coverage|.rescript' -a --dirsfirst

# Count lines of code
loc:
    @tokei --exclude node_modules --exclude .git

# Generate TODO list from code
todos:
    @grep -rn "TODO\|FIXME\|HACK\|XXX" src test --include="*.res" || true

# Security audit
security:
    npm audit

# Check for outdated dependencies
outdated:
    npm outdated

# ============================================================================
# DATABASE & PERSISTENCE
# ============================================================================

# Initialize database
db-init:
    @echo "Initializing corpus database..."
    mkdir -p data/corpus

# Backup database
db-backup:
    tar -czf backups/corpus-$(date +%Y%m%d-%H%M%S).tar.gz data/corpus

# Restore database from backup
db-restore BACKUP:
    tar -xzf {{BACKUP}} -C data/

# ============================================================================
# OPENCYC INTEGRATION
# ============================================================================

# Start OpenCyc connection
cyc-connect:
    @echo "Connecting to OpenCyc knowledge base..."
    node dist/cyc/connect.res.mjs

# Query OpenCyc
cyc-query TERM:
    node dist/cyc/query.res.mjs "{{TERM}}"

# Sync language concepts with OpenCyc
cyc-sync:
    node dist/cyc/sync-languages.res.mjs

# ============================================================================
# GIS INTEGRATION (FUTURE)
# ============================================================================

# Generate language distribution map
gis-map:
    @echo "GIS integration planned - see FUTURE.adoc"

# Export language coordinates
gis-export:
    @echo "GIS integration planned - see FUTURE.adoc"

# ============================================================================
# MISCELLANEOUS
# ============================================================================

# Print environment info
env-info:
    @echo "Node: $(node --version)"
    @echo "npm: $(npm --version)"
    @echo "ReScript: $(npx rescript -version)"
    @echo "Podman: $(podman --version)"
    @echo "Just: $(just --version)"

# Open project repository
repo:
    xdg-open https://github.com/Hyperpolymath/1000Langs

# Open documentation
open-docs:
    xdg-open docs/html/README.html

# Benchmark performance
bench:
    @echo "Running benchmarks..."
    node dist/bench.res.mjs

# Profile memory usage
profile:
    node --inspect dist/Lang1000.res.mjs

# ============================================================================
# MAINTENANCE
# ============================================================================

# Update .gitignore
gitignore:
    curl -sL https://www.toptal.com/developers/gitignore/api/node,rescript,vim,emacs > .gitignore

# Prune git repository
git-prune:
    git gc --prune=now
    git remote prune origin

# Archive old branches
git-archive:
    @echo "Archiving merged branches..."
    git branch --merged | grep -v "main\|master\|\*" | xargs -r git branch -d

# All maintenance tasks
maintain: clean git-prune security outdated
