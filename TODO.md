# break TODO

- [ ] Switch triage parsing to pi's `--schema` structured output once the feature
      ships in the installed pi binary (implemented 2026-09-14, uncommitted in
      ~/repos/pi). Keep parse_bugclasses as fallback. Triage-only: hunters keep
      the findings-file contract; STATUS: line regex stays.
- [ ] `break watch <run-id>` live-tailing hunter session logs
- [ ] Verifier-only run mode: re-check known ledger findings against current code
