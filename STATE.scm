;;; ==================================================
;;; STATE.scm — AI Conversation Checkpoint File
;;; ==================================================
;;;
;;; SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
;;; Copyright (c) 2024-2025 Ehsaneddin Asgari and Contributors
;;;
;;; PROJECT: LOL (1000Langs)
;;; Super-parallel corpus crawler for 1500+ languages
;;;
;;; STATEFUL CONTEXT TRACKING ENGINE
;;; Version: 2.0
;;;
;;; CRITICAL: Download this file at end of each session!
;;; At start of next conversation, upload it.
;;; Do NOT rely on ephemeral storage to persist.
;;;
;;; ==================================================

(define state
  '((metadata
      (format-version . "2.0")
      (schema-version . "2025-12-06")
      (created-at . "2025-12-08T00:00:00Z")
      (last-updated . "2025-12-08T00:00:00Z")
      (generator . "Claude/STATE-system"))

    (user
      (name . "Ehsaneddin Asgari")
      (roles . ("maintainer" "researcher" "computational-linguist"))
      (preferences
        (languages-preferred . ("ReScript" "Nickel" "Scheme"))
        (languages-avoid . ("Python"))
        (tools-preferred . ("GitLab" "Podman" "Nix" "Just" "Vitest" "Biome"))
        (values . ("FOSS" "reproducibility" "formal-verification" "type-safety" "RSR-compliance"))))

    (session
      (conversation-id . "01JLV9XpwzF3vtHN1ZKH8yX6")
      (started-at . "2025-12-08T00:00:00Z")
      (messages-used . 0)
      (messages-remaining . 100)
      (token-limit-reached . #f))

    ;;; ==================================================
    ;;; CURRENT POSITION — What exists and what works
    ;;; ==================================================

    (focus
      (current-project . "LOL-MVP-v1")
      (current-phase . "implementation-gap-closure")
      (deadline . #f)
      (blocking-projects . ()))

    (current-position
      (summary . "Architecture complete, implementations stubbed")

      (done
        ;; Foundation Layer — COMPLETE
        ("Core type system" . "Language, Verse, Corpus, Alignment types")
        ("Base crawler framework" . "Rate limiting, retry policies, request config")
        ("Language code utilities" . "ISO 639-1/2/3 with validation and conversion")
        ("Statistical functions" . "Entropy, KL-divergence, Jensen-Shannon, distance metrics")
        ("OpenCyc ontology types" . "Language/script/region concept mappings defined")
        ("Configuration system" . "Nickel-based with type contracts")
        ("Test infrastructure" . "Vitest setup with ~97 passing tests")
        ("Documentation" . "README.adoc, FUTURE.adoc, CONTRIBUTING.adoc")
        ("RSR Gold Compliance" . "SPDX headers, security policy, accessibility")
        ("Build/Dev tooling" . "Justfile with 70+ recipes, Nix flake, Podman"))

      (partial
        ;; Structural shells exist, implementations missing
        ("Crawler implementations" . "40% - Types defined, HTTP/parsing NOT implemented")
        ("OpenCyc integration" . "30% - Ontology types exist, connection/queries missing")
        ("Proof verification" . "20% - Framework configured, all proofs pending"))

      (not-started
        ("HTTP request layer" . "No actual network calls")
        ("JSON/HTML parsing" . "All parsers return NoMatch")
        ("Data persistence" . "Crawler results not stored")
        ("API authentication" . "Key handling defined, not wired up")
        ("GIS integration" . "Planned in FUTURE.adoc")
        ("ML features" . "Planned for later phases")))

    ;;; ==================================================
    ;;; PROJECTS — Detailed tracking
    ;;; ==================================================

    (projects
      ;; MVP v1 — The Primary Goal
      ((name . "LOL-MVP-v1")
       (status . "in-progress")
       (completion . 45)
       (category . "infrastructure")
       (phase . "implementation")
       (dependencies . ())
       (blockers . ("HTTP layer not implemented" "JSON parsing stubbed"))
       (next . ("Implement HTTP request layer"
                "Implement BibleCloud JSON parsing"
                "Wire up API authentication"
                "Add data persistence (JSONL/gzip)"
                "Integration testing with live API"))
       (chat-reference . #f)
       (notes . "Architecture is solid. Gap is purely implementation of I/O."))

      ;; BibleCloud Crawler — Critical Path for MVP
      ((name . "BibleCloud-Crawler")
       (status . "in-progress")
       (completion . 35)
       (category . "infrastructure")
       (phase . "implementation")
       (dependencies . ("HTTP-Layer"))
       (blockers . ("HTTP layer missing" "JSON parsing returns NoMatch"))
       (next . ("Implement parseBibleCloudResponse"
                "Implement fetchLanguages API call"
                "Add response validation"
                "Error handling for rate limits"))
       (chat-reference . "src/crawlers/BibleCloud.res")
       (notes . "Most promising first crawler. API is well-documented."))

      ;; Digital Bible Platform API
      ((name . "DigitalBiblePlatform-API")
       (status . "blocked")
       (completion . 20)
       (category . "infrastructure")
       (phase . "implementation")
       (dependencies . ("HTTP-Layer" "BibleCloud-Crawler"))
       (blockers . ("All 6 API methods return NotImplemented"))
       (next . ("Implement getBibles" "Implement getVerses" "Implement getPassage"))
       (chat-reference . "src/api/DigitalBiblePlatform.res:126-154")
       (notes . "6 stubbed methods. Lower priority than BibleCloud."))

      ;; OpenCyc Integration
      ((name . "OpenCyc-Integration")
       (status . "paused")
       (completion . 25)
       (category . "ai")
       (phase . "design")
       (dependencies . ("LOL-MVP-v1"))
       (blockers . ("Server connection not implemented" "Query execution stubbed"))
       (next . ("Decide if needed for MVP"
                "Implement CycConnection"
                "Implement query execution"))
       (chat-reference . "src/cyc/OpenCyc.res")
       (notes . "5 TODOs in module. Post-MVP unless essential."))

      ;; Formal Proofs
      ((name . "Echidna-Proofs")
       (status . "paused")
       (completion . 15)
       (category . "formal-verification")
       (phase . "planning")
       (dependencies . ("LOL-MVP-v1"))
       (blockers . ("All proofs status: Pending"))
       (next . ("Complete alignment correctness proof"
                "Verify statistics implementation"
                "ISO 639 validation proofs"))
       (chat-reference . "proofs/")
       (notes . "Infrastructure ready. Proofs themselves not written."))

      ;; GIS Integration
      ((name . "GIS-Language-Maps")
       (status . "paused")
       (completion . 0)
       (category . "infrastructure")
       (phase . "planning")
       (dependencies . ("LOL-MVP-v1"))
       (blockers . ())
       (next . ("Review FUTURE.adoc Phase 1"
                "Evaluate Leaflet vs ArcGIS"
                "Glottolog data import design"))
       (chat-reference . "FUTURE.adoc")
       (notes . "Post-MVP. 2-3 months effort per FUTURE.adoc.")))

    ;;; ==================================================
    ;;; ROUTE TO MVP v1 — Implementation Roadmap
    ;;; ==================================================

    (mvp-v1-route
      (target-definition . "One working crawler fetching real data with persistence")

      (phase-1-http-layer
        (status . "not-started")
        (effort . "1 week")
        (tasks . ("Choose HTTP library (node-fetch or axios)"
                  "Create generic request wrapper"
                  "Implement rate limiting middleware"
                  "Add retry with exponential backoff"
                  "Error type mapping")))

      (phase-2-biblecloud-crawler
        (status . "not-started")
        (effort . "1-2 weeks")
        (dependencies . ("phase-1-http-layer"))
        (tasks . ("Implement parseBibleCloudResponse JSON parsing"
                  "Implement fetchLanguages API call"
                  "Implement fetchBible and fetchChapter"
                  "Add response validation"
                  "Integration tests with mock server"
                  "Integration tests with live API (rate-limited)")))

      (phase-3-data-persistence
        (status . "not-started")
        (effort . "1 week")
        (dependencies . ("phase-2-biblecloud-crawler"))
        (tasks . ("Choose storage format (JSONL recommended)"
                  "Implement corpus writer"
                  "Add gzip compression"
                  "Incremental/resumable crawling"
                  "Data validation on write")))

      (phase-4-polish-and-release
        (status . "not-started")
        (effort . "3-5 days")
        (dependencies . ("phase-3-data-persistence"))
        (tasks . ("Full test coverage for new code"
                  "Update documentation"
                  "Version bump to 1.0.0"
                  "Container image release"
                  "CHANGELOG update"))))

    ;;; ==================================================
    ;;; ISSUES — Known problems and technical debt
    ;;; ==================================================

    (issues
      (critical
        ("No HTTP implementation" . "All crawlers are structural shells only")
        ("All parsers return NoMatch" . "JSON/HTML parsing not implemented"))

      (high
        ("OpenCyc connection stubbed" . "src/cyc/OpenCyc.res:90")
        ("DBP API all NotImplemented" . "src/api/DigitalBiblePlatform.res:126-154")
        ("Query execution stubbed" . "src/cyc/OpenCyc.res:133"))

      (medium
        ("Proofs all pending" . "proofs/ directory")
        ("No data persistence" . "Crawled data not stored")
        ("API key handling not wired" . "Config defined, not used"))

      (low
        ("No CLI interface" . "Just recipes exist, no direct CLI")
        ("Container not tested" . "Containerfile exists, untested")))

    ;;; ==================================================
    ;;; QUESTIONS FOR USER — Decisions needed
    ;;; ==================================================

    (questions
      ;; MVP Scope Questions
      ((id . "Q1")
       (category . "mvp-scope")
       (question . "Should MVP v1 deliver a working crawler, or is the type-safe framework sufficient?")
       (options . ("Working crawler with real data"
                   "Framework only, crawlers post-MVP"
                   "Hybrid: one crawler working, others stubbed"))
       (recommendation . "Working crawler — proves the architecture"))

      ((id . "Q2")
       (category . "mvp-scope")
       (question . "Is OpenCyc integration required for MVP, or can it be stubbed/post-MVP?")
       (options . ("Required for MVP"
                   "Post-MVP enhancement"
                   "Stub with mock data for MVP"))
       (recommendation . "Post-MVP — focus on core crawling first"))

      ((id . "Q3")
       (category . "mvp-scope")
       (question . "Are formal proofs (Echidna) required before v1 release?")
       (options . ("Yes, proofs must pass"
                   "No, proofs can be post-v1"
                   "Core proofs only (alignment, statistics)"))
       (recommendation . "Post-v1 — proofs don't block functionality"))

      ;; Technical Questions
      ((id . "Q4")
       (category . "technical")
       (question . "Preferred HTTP library for ReScript?")
       (options . ("node-fetch (lighter)"
                   "axios (more features)"
                   "Custom bindings to fetch API"))
       (recommendation . "node-fetch — minimal, sufficient for crawling"))

      ((id . "Q5")
       (category . "technical")
       (question . "Data storage format for corpus?")
       (options . ("JSONL (line-delimited JSON)"
                   "Parquet (columnar, compressed)"
                   "SQLite (relational)"
                   "Custom binary format"))
       (recommendation . "JSONL with gzip — simple, streaming, compressible"))

      ((id . "Q6")
       (category . "technical")
       (question . "How many languages should MVP v1 support?")
       (options . ("All 1500+ from day one"
                   "Subset (e.g., top 100 by speakers)"
                   "Single language family for testing"))
       (recommendation . "Start with subset, validate, then expand"))

      ;; Process Questions
      ((id . "Q7")
       (category . "process")
       (question . "Preferred development order for crawlers?")
       (options . ("BibleCloud first (API-based, 1500+ languages)"
                   "Bible.com first (scraping, 2000+ languages)"
                   "PNGScriptures first (simplest, 800+ languages)"))
       (recommendation . "BibleCloud — API is more stable than scraping"))

      ((id . "Q8")
       (category . "process")
       (question . "Should GIS integration be prioritized after MVP, or other features first?")
       (options . ("GIS next (visual impact)"
                   "More crawlers next (data breadth)"
                   "ML features next (research value)"))
       (recommendation . "More crawlers — maximize corpus before visualization")))

    ;;; ==================================================
    ;;; LONG-TERM ROADMAP — Vision and milestones
    ;;; ==================================================

    (roadmap
      (vision . "The definitive super-parallel corpus for 1500+ languages with type-safe, formally verified infrastructure")

      (v1-mvp
        (target . "One working crawler with data persistence")
        (status . "in-progress")
        (completion . 45)
        (milestones . ("HTTP layer" "BibleCloud crawler" "JSONL persistence" "Release 1.0.0")))

      (v1-1-additional-crawlers
        (target . "All planned crawlers operational")
        (status . "planned")
        (completion . 0)
        (milestones . ("Bible.com scraper"
                       "PNGScriptures downloader"
                       "eBible integration"
                       "Find.Bible API"
                       "unfoldingWord integration")))

      (v1-2-corpus-quality
        (target . "Validated, aligned, deduplicated corpus")
        (status . "planned")
        (completion . 0)
        (milestones . ("Alignment verification"
                       "Duplicate detection"
                       "Quality scoring"
                       "Coverage reporting")))

      (v2-0-semantic-integration
        (target . "OpenCyc-powered language reasoning")
        (status . "planned")
        (completion . 0)
        (milestones . ("CycConnection implementation"
                       "Language classification"
                       "Script compatibility"
                       "Geographic plausibility")))

      (v2-1-formal-verification
        (target . "All proofs passing in Echidna")
        (status . "planned")
        (completion . 0)
        (milestones . ("Alignment correctness proof"
                       "Statistics implementation proof"
                       "ISO 639 validation proof"
                       "Crawler invariant proofs")))

      (v3-0-gis-integration
        (target . "Interactive language maps")
        (status . "planned")
        (completion . 0)
        (milestones . ("Glottolog import"
                       "Leaflet map integration"
                       "Corpus coverage visualization"
                       "Typological feature overlays"
                       "Historical animations")))

      (v4-0-ml-features
        (target . "Machine learning for corpus analysis")
        (status . "planned")
        (completion . 0)
        (milestones . ("Language identification"
                       "Script detection"
                       "Translation quality estimation"
                       "Alignment refinement")))

      (v5-0-research-tools
        (target . "Full computational linguistics toolkit")
        (status . "planned")
        (completion . 0)
        (milestones . ("Typological analysis"
                       "Phylogenetic construction"
                       "Lexical similarity"
                       "Cross-linguistic search"))))

    ;;; ==================================================
    ;;; CRITICAL NEXT ACTIONS — Immediate priorities
    ;;; ==================================================

    (critical-next
      ("Implement HTTP request layer in ReScript"
       "Implement BibleCloud JSON parsing (parseBibleCloudResponse)"
       "Wire up API authentication for BibleCloud"
       "Create JSONL writer for corpus persistence"
       "Integration test with live BibleCloud API"))

    ;;; ==================================================
    ;;; TECHNICAL DEBT — Items to address
    ;;; ==================================================

    (technical-debt
      ("15 TODOs across codebase"
       "6 NotImplemented methods in DBP API"
       "All OpenCyc queries stubbed"
       "Proofs pending verification"
       "No error recovery beyond type definitions"))

    ;;; ==================================================
    ;;; HISTORY — Velocity tracking
    ;;; ==================================================

    (history
      (snapshots
        ((timestamp . "2025-12-08T00:00:00Z")
         (event . "STATE.scm created")
         (projects
           ((name . "LOL-MVP-v1") (completion . 45))
           ((name . "BibleCloud-Crawler") (completion . 35))
           ((name . "DigitalBiblePlatform-API") (completion . 20))
           ((name . "OpenCyc-Integration") (completion . 25))
           ((name . "Echidna-Proofs") (completion . 15))
           ((name . "GIS-Language-Maps") (completion . 0))))))

    ;;; ==================================================
    ;;; SESSION TRACKING
    ;;; ==================================================

    (files-created-this-session
      ("STATE.scm"))

    (files-modified-this-session
      ())

    (context-notes . "Initial STATE.scm creation. Project rewritten from Python to ReScript. Architecture is complete and type-safe. Primary gap is I/O implementation: HTTP requests, parsing, and persistence. MVP v1 requires completing one end-to-end crawler.")))

;;; ==================================================
;;; QUICK REFERENCE
;;; ==================================================
;;;
;;; Load the library for full functionality:
;;;
;;;   (add-to-load-path "/path/to/STATE.djot/lib")
;;;   (use-modules (state))
;;;
;;; Core queries:
;;;   (get-current-focus state)      ; Current project name
;;;   (get-blocked-projects state)   ; All blocked projects
;;;   (get-critical-next state)      ; Priority actions
;;;   (should-checkpoint? state)     ; Need to save?
;;;
;;; minikanren queries:
;;;   (run* (q) (statuso q "blocked" state))  ; All blocked
;;;   (run* (q) (dependso "ProjectA" q state)) ; Dependencies
;;;
;;; Visualization:
;;;   (generate-dot state)           ; GraphViz DOT output
;;;   (generate-mermaid state)       ; Mermaid diagram
;;;
;;; Time estimation:
;;;   (project-velocity "Project" state)       ; %/day
;;;   (estimate-completion-date "Project" state) ; ISO date
;;;   (velocity-report state)        ; Print velocity report
;;;   (progress-report state)        ; Print progress report
;;;
;;; History management:
;;;   (create-snapshot state)        ; Create new snapshot
;;;   (add-snapshot-to-history snapshot state) ; Add to history
;;;
;;; ==================================================
;;; END STATE.scm
;;; ==================================================
