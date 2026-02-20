# Story 4.1: Core Logging Library with Gum Integration

Status: done

## Story

As a developer,
I want a logging library with configurable levels and Gum support,
so that I can add structured logging to my build scripts with beautiful terminal output.

## Acceptance Criteria

1. **Given** the logging library is initialized **When** `GUM_LOG_LEVEL` is set to `info` (default) **Then** only info, warning, and error messages are displayed **And** debug messages are suppressed

2. **Given** Gum is not installed on the system **When** logging functions are called **Then** the library falls back to plain `echo` output **And** messages still include log level prefixes (e.g., "[INFO]", "[ERROR]")

3. **Given** the build process starts **When** `print_header()` is called **Then** it displays a beautifully formatted header with 🚀 emoji **And** includes image name, profile, base reference, and timestamp **And** uses double border styling with purple (#8B5CF6) color

4. **Given** the build process completes **When** `print_footer()` is called with success status **Then** it displays a green-bordered footer with ✅ emoji **And** includes duration, image size, layers, packages, and tags

5. **Given** a build phase begins **When** `start_phase()` is called with phase name **Then** it displays ▶️ Phase header with rounded border **And** uses blue (#3B82F6) color for the phase indicator

6. **Given** a build phase completes **When** `end_phase()` is called **Then** it displays ✅ Phase complete with ⏱️ duration **And** uses green (#10B981) color for success indicator

7. **Given** the Containerfile has multiple RUN stages **When** each RUN stage executes **Then** phases are dynamically created based on layer count **And** phase numbering adapts to total number of layers

## Tasks / Subtasks

- [x] Create `files/scripts/lib.sh` with core logging functions (AC: 1-7)
  - [x] Implement `log_init()` for configuration initialization
  - [x] Implement `log_debug()`, `log_info()`, `log_warn()`, `log_error()`, `log_success()`
  - [x] Implement `gum_available()` check function
  - [x] Implement fallback echo-based logging
- [x] Implement header/footer functions (AC: 3-4)
  - [x] `print_header()` with Gum border styling
  - [x] `print_footer()` with success/failure states
- [x] Implement phase management (AC: 5-7)
  - [x] `start_phase()` with dynamic numbering
  - [x] `end_phase()` with duration tracking
- [x] Add environment variable support
  - [x] `GUM_LOG_LEVEL` (debug/info/warn/error)
  - [x] Default to `info` if unset

## Dev Notes

### Architecture Constraints
- Location: `files/scripts/lib.sh` (single source of truth)
- Must work within Fedora Atomic/bootc container build system
- Zero interactivity - optimized for CI/CD

### Fallback Mechanism
Every function must check `gum_available()` before using Gum commands. Fall back to plain `echo` with bracketed log levels.

### Performance Requirements
- Logging overhead: < 1% of build time
- Memory usage: < 10MB for log buffering
- Startup time: < 100ms for initialization

### References
- PRD: `_bmad-output/planning-artifacts/epic-logging/gum-logging-prd.md`
- Epics: `_bmad-output/planning-artifacts/epic-logging/epics.md`
- Architecture: `_bmad-output/planning-artifacts/architecture.md`

## Dev Agent Record

### Agent Model Used

opencode/glm-5-free

### Debug Log References

- Tested log level filtering with all levels (debug, info, warn, error)
- Verified Gum fallback mechanism by forcing `_GUM_AVAILABLE="false"`
- Confirmed header/footer output formatting with both Gum and fallback modes
- Validated phase management with dynamic numbering via `set_phase_total()`

### Completion Notes List

1. Implemented complete logging library in `files/scripts/lib.sh` with Gum integration
2. Log levels: debug, info, warn, error - controlled via `GUM_LOG_LEVEL` env var (default: info)
3. Fallback mechanism: When Gum unavailable, uses ANSI-colored echo with `[LEVEL]` prefixes
4. `print_header()`: Double border, purple (#8B5CF6), displays image/profile/base/timestamp
5. `print_footer()`: Color-coded by status (green success, red failure), displays duration/size/layers/packages/tags
6. `start_phase()`: Rounded border, blue (#3B82F6), dynamic phase numbering
7. `end_phase()`: Green duration display, calculates elapsed time
8. Added `set_phase_total()` for dynamic layer count adaptation
9. Added `get_build_duration()` for total build time tracking
10. Preserved existing utility functions: `die()`, `err()`, `section()`, `dnf_install_quiet()`, `copr_enable_quiet()`, `curl_fetch()`, `curl_get()`, `unarchive()`
11. All code passes shellcheck validation

### File List

- `files/scripts/lib.sh` (modified)

---

## Senior Developer Review (AI)

### Review Date
2026-02-20

### Review Outcome
**Approve** - All acceptance criteria implemented, code quality issues addressed

### Issues Found

| ID | Severity | Description | Status |
|----|----------|-------------|--------|
| MED-1 | Medium | File List incomplete (sprint-status.yaml not listed) | Fixed - tracked in git only |
| MED-2 | Medium | GitHub annotations incomplete (only error/warn) | ✅ Fixed |
| MED-3 | Medium | Performance requirements not verified | Deferred - runtime validation |
| MED-4 | Medium | `section()` function inconsistent with Gum styling | ✅ Fixed |
| MED-5 | Medium | Error messages suppressed in `curl_get()` and `unarchive()` | ✅ Fixed |
| LOW-1 | Low | Magic number for default phase total | ✅ Fixed - added comment |
| LOW-2 | Low | No documentation comments | ✅ Fixed - added header docstring |

### Fixes Applied

1. **GitHub annotations** - Added `::debug::`, `::notice::` for all log levels
2. **section() consistency** - Now uses Gum border styling with fallback
3. **Error messages** - Removed `2>/dev/null` suppression in `curl_get()` and `unarchive()`
4. **Documentation** - Added comprehensive header docstring with usage example
5. **Code comments** - Added comment explaining default `_PHASE_TOTAL=8`

### Deferred Items

- JSON mode implementation (GUM_LOG_FORMAT) - reserved for future story
- Unit test suite - runtime validation in actual builds

