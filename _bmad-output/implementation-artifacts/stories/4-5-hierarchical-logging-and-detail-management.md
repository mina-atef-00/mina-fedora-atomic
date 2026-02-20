# Story 4.5: Hierarchical Logging and Detail Management

Status: done

## Story

As a developer,
I want structured hierarchical logging with multiple detail levels,
so that I can organize log output logically and control verbosity.

## Acceptance Criteria

1. **Given** `log_item()` is called with message and indent level **When** displaying phase actions (level 1) **Then** output is indented 2 spaces from left margin **And** uses ✅ icon prefix

2. **Given** `log_detail()` is called **When** displaying details under actions (level 2) **Then** output is indented 4 spaces from left margin **And** uses → icon prefix **And** uses white (#E5E7EB) color for text

3. **Given** `log_subdetail()` is called **When** displaying sub-lists (level 3) **Then** output is indented 6 spaces from left margin **And** uses • icon prefix **And** uses dim (#9CA3AF) color for secondary text

4. **Given** `log_check()` is called **When** marking items as completed **Then** output is indented 2 spaces **And** uses ✅ icon in green (#10B981) color **And** text is descriptive of the completed action

5. **Given** multiple levels are used in sequence **When** parent → child → grandchild structure is created **Then** indentation is consistent (2→4→6 spaces) **And** visual hierarchy is clear and scannable

## Tasks / Subtasks

- [x] Implement `log_item()` function (AC: 1)
  - [x] 2-space indentation
  - [x] ✅ icon prefix
  - [x] Gum formatting support
- [x] Implement `log_detail()` function (AC: 2)
  - [x] 4-space indentation
  - [x] → icon prefix
  - [x] White (#E5E7EB) color
- [x] Implement `log_subdetail()` function (AC: 3)
  - [x] 6-space indentation
  - [x] • icon prefix
  - [x] Dim (#9CA3AF) color
- [x] Implement `log_check()` function (AC: 4)
  - [x] 2-space indentation
  - [x] Green ✅ icon
  - [x] Descriptive text support
- [x] Ensure hierarchy consistency (AC: 5)
  - [x] Visual alignment across levels
  - [x] Clear parent-child relationships

## Dev Notes

### Hierarchical Logging Structure

```
▶️ Phase 3/8: Package Installation

  ✅ Installing system packages (log_item)
    → dnf5-plugins (log_detail)
    → fish shell (log_detail)
    → neovim (log_detail)
      • v0.10+ required (log_subdetail)
      • with Lua support (log_subdetail)

  ✅ Configuring repositories (log_check)
```

### Indentation Reference

| Level | Indent | Icon | Color | Function |
|-------|--------|------|-------|----------|
| 1 | 2 spaces | ✅ | Default | `log_item()` |
| 2 | 4 spaces | → | White #E5E7EB | `log_detail()` |
| 3 | 6 spaces | • | Dim #9CA3AF | `log_subdetail()` |
| Check | 2 spaces | ✅ | Green #10B981 | `log_check()` |

### Function Signatures

```bash
log_item()      # $1: icon (default: ✅), $2: message, $3: indent_level (1-3), $4: optional color
log_detail()    # $1: message - uses → icon, 4-space indent, white color
log_subdetail() # $1: message - uses • icon, 6-space indent, dim color
log_check()     # $1: message - uses ✅ icon, 2-space indent, green color
```

### Dependencies
- Requires Story 4.1 (core logging functions)
- Requires Story 4.2 (visual design system for colors)

### References
- PRD: `_bmad-output/planning-artifacts/epic-logging/gum-logging-prd.md` (Section 3.4)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Implemented hierarchical logging functions (log_item, log_detail, log_subdetail, log_check) in lib.sh
- Modified log_item() to accept optional color parameter for flexible styling
- Updated log_detail() to use white (#E5E7EB) color per AC2
- Updated log_subdetail() to use dim (#9CA3AF) color per AC3
- Updated log_check() to use green (#10B981) color per AC4
- Added 17 new unit tests covering all AC requirements
- All 101 tests pass including new hierarchical logging tests
- Fixed function signature documentation in Dev Notes (was incorrect)
- Fixed argument handling in log_detail/log_subdetail/log_check using `$@` instead of `$*`
- Added 6 new gum-mode and argument handling tests
- Total 111 tests now pass

### File List

- `files/scripts/lib.sh` - Modified log_item(), log_detail(), log_subdetail(), log_check() functions to support color parameter and meet AC requirements; fixed argument handling
- `files/scripts/tests/test-lib.sh` - Added 23 new tests for hierarchical logging functions (including gum-mode tests)

## Change Log

- 2026-02-20: Implemented hierarchical logging functions with proper indentation (2/4/6 spaces), icons (✅/→/•), and colors per AC requirements
- 2026-02-20: Code review fixes - corrected Dev Notes function signature, added gum-mode tests, fixed argument handling with `$@`
