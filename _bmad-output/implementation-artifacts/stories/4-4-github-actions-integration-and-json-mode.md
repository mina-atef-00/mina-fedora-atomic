# Story 4.4: GitHub Actions Integration and JSON Mode

Status: done

## Story

As a DevOps engineer,
I want logs compatible with GitHub Actions and JSON output support,
so that CI/CD pipelines can parse and process build logs programmatically.

## Acceptance Criteria

1. **Given** `GUM_LOG_FORMAT` is set to `json` **When** any log function is called **Then** output is valid JSON format **And** includes timestamp, level, message, and metadata fields

2. **Given** JSON mode is enabled **When** a phase starts **Then** JSON output includes phase number, name, and timestamp

3. **Given** JSON mode is enabled **When** an error occurs **Then** JSON output includes error details, phase, and suggested fixes

4. **Given** running in GitHub Actions environment **When** `log_error()` is called **Then** `::error file=Containerfile,line=1::message` is output **And** JSON/text output is also generated based on GUM_LOG_FORMAT

5. **Given** running in GitHub Actions environment **When** `log_warn()` is called **Then** `::warning file=Containerfile,line=1::message` is output

6. **Given** `GUM_LOG_LEVEL` is set to `debug` **When** verbose logging is requested **Then** all suppressed DNF5 output is shown **And** warning deduplication is disabled **And** full package installation details are visible

7. **Given** `GUM_LOG_LEVEL` is set to `warn` **When** quiet monitoring is needed **Then** only warnings and errors are displayed **And** info messages are suppressed

8. **Given** `GUM_LOG_LEVEL` is set to `error` **When** critical monitoring is needed **Then** only errors are displayed **And** all other messages are suppressed

## Tasks / Subtasks

- [x] Implement JSON output mode (AC: 1-3)
  - [x] Add `GUM_LOG_FORMAT` environment variable support
  - [x] Create `output_json()` function for structured logging
  - [x] Include timestamp (ISO 8601), level, message, metadata
  - [x] JSON structure for phases and errors
- [x] Implement GitHub Actions detection (AC: 4-5)
  - [x] Check `GITHUB_ACTIONS` environment variable
  - [x] Generate `::error::` annotations with file/line context
  - [x] Generate `::warning::` annotations
  - [x] Maintain visual output alongside annotations
- [x] Implement log level filtering (AC: 6-8)
  - [x] Debug mode: show all output, disable deduplication
  - [x] Warn mode: suppress info, show warnings/errors
  - [x] Error mode: show only errors

## Dev Notes

### JSON Output Structure

```json
{
  "timestamp": "2026-02-19T14:32:15.123Z",
  "level": "info",
  "message": "Package installation complete",
  "metadata": {
    "phase": 3,
    "phase_name": "Package Installation",
    "duration_seconds": 45
  }
}
```

### JSON Error Structure

```json
{
  "timestamp": "2026-02-19T14:35:22.456Z",
  "level": "error",
  "message": "Package not found: nonexistent-package",
  "metadata": {
    "phase": 3,
    "phase_name": "Package Installation",
    "suggested_fixes": [
      "Check package name spelling",
      "Enable required repositories"
    ]
  }
}
```

### Environment Variables

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `GUM_LOG_LEVEL` | `info` | debug, info, warn, error | Verbosity control |
| `GUM_LOG_FORMAT` | `text` | text, json | Output format |

### CI Detection
- Check `GITHUB_ACTIONS=true` for GitHub Actions
- Check `CI=true` as generic CI indicator

### Dependencies
- Requires Story 4.1 (core logging functions)
- Requires Story 4.2 (visual design system)
- Requires Story 4.3 (filtering and error handling)

### References
- PRD: `_bmad-output/planning-artifacts/epic-logging/gum-logging-prd.md` (Sections 4.2.1, 4.2.2)

## Dev Agent Record

### Agent Model Used

opencode/glm-5-free

### Debug Log References

### Completion Notes List

- **2026-02-20**: Implemented JSON output mode with `output_json()` function that produces valid JSON with ISO 8601 timestamps, level, message, and optional metadata
- **2026-02-20**: Added `_output_json_phase()` and `_output_json_error()` functions for structured phase and error logging
- **2026-02-20**: Modified `log()` function to detect JSON mode and route to appropriate output formatter
- **2026-02-20**: Updated `start_phase()` to output JSON when `GUM_LOG_FORMAT=json`
- **2026-02-20**: Enhanced `display_error_block()` to output JSON errors with suggested fixes
- **2026-02-20**: Updated `_emit_github_annotation()`, `_display_github_error()`, and `_display_github_warning()` to default to `file=Containerfile,line=1` for AC4 and AC5 compliance
- **2026-02-20**: Modified `log_error()` and `log_warn()` to emit GitHub annotations with default file/line context
- **2026-02-20**: Verified log level filtering works correctly for debug/warn/error modes
- **2026-02-20**: All tests pass including new JSON mode and GitHub Actions tests

### Senior Developer Review (AI)

#### Review Date
2026-02-20

#### Review Outcome
Approve with Minor Fixes

#### Action Items
- [x] [HIGH] Fix JSON injection vulnerability - add proper escaping for special characters
- [x] [HIGH] Fix double GitHub annotation emission - annotations were being emitted twice
- [x] [MEDIUM] Add CI=true detection support for generic CI environments
- [x] [MEDIUM] Fix misleading timestamp precision - use proper ISO 8601 format without hardcoded milliseconds
- [x] [MEDIUM] Remove dead code in _output_json_phase function
- [x] [LOW] Update outdated header comment about JSON support
- [x] [LOW] Add test for JSON+GitHub Actions combo mode
- [x] [LOW] Add end_phase JSON output for consistency

#### Review Follow-ups (AI)

### File List

- files/scripts/lib.sh
- files/scripts/tests/test-lib.sh

### Change Log

- 2026-02-20: Implemented JSON output mode, GitHub Actions integration with file/line defaults, and log level filtering (Story 4.4)
- 2026-02-20: Code review fixes - JSON escaping, duplicate annotation fix, CI=true support, timestamp format
