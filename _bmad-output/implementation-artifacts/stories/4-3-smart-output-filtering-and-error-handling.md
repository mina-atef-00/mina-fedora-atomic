# Story 4.3: Smart Output Filtering and Error Handling

Status: done

## Story

As a system administrator,
I want verbose output filtered and errors clearly displayed,
so that logs stay concise while critical issues are immediately visible.

## Acceptance Criteria

1. **Given** DNF5 is installing packages **When** progress indicators appear (lines starting with `[`) **Then** they are suppressed from the log output **And** only package installation summaries are shown

2. **Given** DNF5 outputs "Copying blob" messages **When** these messages appear **Then** they are filtered out entirely **And** not displayed in the log

3. **Given** DNF5 outputs "Writing manifest" messages **When** these messages appear **Then** they are filtered out entirely

4. **Given** DNF5 shows "100% |" progress lines **When** these appear during package download **Then** they are suppressed **And** only final completion is shown

5. **Given** DNF5 shows transfer rates ("KiB/s") **When** these appear **Then** they are filtered out

6. **Given** DNF5 outputs "Complete!" messages repeatedly **When** these appear for each package **Then** only the first occurrence is shown **And** subsequent occurrences are counted and summarized

7. **Given** a warning appears multiple times **When** the same warning type is encountered **Then** only the first instance is displayed **And** a count of suppressed warnings is shown (e.g., "⚠️ 5 similar warnings suppressed") **And** the message indicates how to see all warnings (--verbose flag)

8. **Given** a build error occurs **When** `log_error()` is called with error details **Then** a red-bordered error block is displayed **And** includes current phase name and step **And** shows descriptive error message **And** lists suggested fixes as bullet points (→) **And** displays duration until failure with ⏱️ emoji

9. **Given** a critical error occurs during package installation **When** the error is logged **Then** GitHub Actions annotations are generated (`::error::`) **And** visual error block is still displayed in terminal

10. **Given** a warning is logged in CI environment **When** `log_warn()` is called **Then** GitHub Actions annotations are generated (`::warning::`) **And** visual warning is displayed in terminal

## Tasks / Subtasks

- [x] Implement DNF5 output filter function (AC: 1-6)
  - [x] Create `filter_dnf_output()` function
  - [x] Filter patterns: `[`, "Copying blob", "Writing manifest", "100% |", "KiB/s", "Complete!"
  - [x] Return filtered/summarized output
- [x] Implement warning suppression (AC: 7)
  - [x] Track warning counts by type
  - [x] Show first occurrence only
  - [x] Display suppression count with --verbose hint
- [x] Implement error display function (AC: 8)
  - [x] `display_error_block()` with red border
  - [x] Include phase/step context
  - [x] Show suggested fixes as bullets
  - [x] Display duration with emoji
- [x] Implement GitHub Actions annotations (AC: 9-10)
  - [x] Detect CI environment (`GITHUB_ACTIONS` env var)
  - [x] Generate `::error::` and `::warning::` annotations
  - [x] Include file/line context when available

## Dev Notes

### DNF5 Filter Patterns

Suppress these patterns:
```
^\[                          # Lines starting with [
Copying blob
Writing manifest
100% \|
KiB/s
Complete!
```

### Error Block Format
```
┌─────────────────────────────────────────┐
│                                         │
│   ❌  ERROR                             │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                         │
│   Phase: Package Installation           │
│   Step: Installing dependencies         │
│   Duration: ⏱️ 2m 34s                   │
│                                         │
│   Error: Package not found              │
│                                         │
│   Suggested Fixes:                      │
│   → Check package name spelling         │
│   → Enable required repositories        │
│   → Update package cache                │
│                                         │
└─────────────────────────────────────────┘
```

### GitHub Actions Annotations
```
::error file=Containerfile,line=42::Package installation failed
::warning file=Containerfile,line=15::Deprecated package version
```

### Dependencies
- Requires Story 4.1 (core logging functions)
- Requires Story 4.2 (visual design system) for colors/formatting

### References
- PRD: `_bmad-output/planning-artifacts/epic-logging/gum-logging-prd.md` (Sections 3.5, 3.6)

## Dev Agent Record

### Agent Model Used

opencode/glm-5-free

### Debug Log References

- All 44 tests pass for DNF5 output filtering, warning suppression, error display, and GitHub Actions annotations
- Shellcheck validation passed with no warnings
- Verified filter patterns match AC 1-6 requirements
- Confirmed warning suppression tracks and summarizes correctly
- Error block displays with red border, phase/step context, suggested fixes, and duration
- Code review fixes applied: log_error rich context, dnf_install_quiet exit codes, reset functions

### Completion Notes List

1. Implemented `filter_dnf_output()` function that suppresses: `[` progress indicators, "Copying blob", "Writing manifest", "100% |" progress lines, "KiB/s" transfer rates
2. Added Complete! message handling - shows first occurrence, counts subsequent occurrences, displays summary
3. Implemented `track_warning()` to count warnings by type (normalized key), shows first occurrence only
4. Implemented `emit_warning_summary()` to display suppression count with --verbose hint
5. Implemented `display_error_block()` with red-bordered error block, phase/step context, suggested fixes as → bullets, and ⏱️ duration
6. Implemented `_display_github_error()` and `_display_github_warning()` for CI annotations with file/line context support
7. Added `set_phase_context()` and `set_step_context()` for tracking current operation context
8. Added global variables: `_CURRENT_PHASE`, `_CURRENT_STEP`, `_ERROR_START_TIME`, `_WARNING_COUNTS`, `_COMPLETE_COUNT`, `_VERBOSE_MODE`
9. Updated `dnf_install_quiet()` to use new `filter_dnf_output()` function with proper exit code handling
10. Created comprehensive test suite in `files/scripts/tests/test-lib.sh` with 44 passing tests

### Code Review Fixes Applied

1. **HIGH-1**: `log_error()` now supports rich context - when called with multiple args, it invokes `display_error_block()` for detailed error display
2. **HIGH-2**: `dnf_install_quiet()` now properly captures and returns exit codes instead of masking them via pipe
3. **MED-1**: `filter_dnf_output()` resets `_COMPLETE_COUNT` at start of each invocation
4. **MED-2**: Added `_VERBOSE_MODE` support - set `GUM_LOG_LEVEL=debug` to see all warnings without suppression
5. **MED-3**: Added Gum mode test (runs when gum is available)
6. **MED-4**: Added `reset_warnings()` function to clear warning counts between phases/builds
7. **LOW-1**: Updated File List to include sprint-status.yaml

### File List

- `files/scripts/lib.sh` (modified)
- `files/scripts/tests/test-lib.sh` (created)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified)

## Change Log

- 2026-02-20: Implemented smart output filtering with DNF5 filter, warning suppression, error display block, and GitHub Actions annotations
- 2026-02-20: Code review fixes - log_error rich context, exit code handling, verbose mode, reset functions

---

## Senior Developer Review (AI)

### Review Date
2026-02-20

### Review Outcome
**Approve** - All acceptance criteria implemented, code review issues fixed

### Issues Found

| ID | Severity | Description | Status |
|----|----------|-------------|--------|
| HIGH-1 | HIGH | `log_error()` did not call `display_error_block()` for rich errors | ✅ Fixed |
| HIGH-2 | HIGH | `dnf_install_quiet()` masked exit codes via pipe | ✅ Fixed |
| MED-1 | MEDIUM | `_COMPLETE_COUNT` not reset between calls | ✅ Fixed |
| MED-2 | MEDIUM | No actual --verbose flag handling | ✅ Fixed |
| MED-3 | MEDIUM | No Gum mode tests | ✅ Fixed |
| MED-4 | MEDIUM | `_WARNING_COUNTS` never reset | ✅ Fixed |
| LOW-1 | LOW | sprint-status.yaml not in File List | ✅ Fixed |
| LOW-2 | LOW | No integration tests | Deferred - runtime validation |

### Fixes Applied

1. **log_error rich context**: `log_error()` now accepts optional suggested_fixes, file, line parameters
2. **Exit code handling**: `dnf_install_quiet()` captures output first, then processes and returns proper exit code
3. **Counter reset**: `filter_dnf_output()` resets `_COMPLETE_COUNT=0` at start
4. **Verbose mode**: Setting `GUM_LOG_LEVEL=debug` enables `_VERBOSE_MODE` which shows all warnings
5. **Gum mode test**: Added test that runs when gum is available on system
6. **reset_warnings()**: New function to clear warning counts for new phases/builds
7. **File List updated**: Added sprint-status.yaml

### Deferred Items

- Integration tests with real DNF5 output - requires runtime validation in actual builds
