---
name: Gum-Based Logging System for Bootc Image Builds
description: A visually stunning, informative, and user-friendly logging system using Charmbracelet Gum for bootc image builds
version: 1.0.0
status: Draft
---

# Product Requirements Document (PRD)

## 1. Overview

### 1.1 Product Name
Gum-Based Logging System for Bootc Image Builds

### 1.2 Problem Statement
Current bootc image build logs suffer from two extremes:
- **Old logs**: Too verbose (3000+ lines), with timestamps on every line, every package download showing granular progress, and DNF5 output completely unfiltered. Information is buried in noise, making it impossible to scan.
- **New logs**: Too quiet, missing step indicators, progress tracking, and visual hierarchy. Users feel lost and confused about build state.

### 1.3 Solution
Implement a **Gum-based structured logging system** that provides:
- Visual hierarchy with clear sections and phases
- Smart filtering of verbose output (DNF5, package downloads)
- Emoji-based visual indicators for quick scanning
- Beautiful terminal styling with Lip Gloss
- Configurable log levels for different environments
- Zero interactivity (optimized for CI/CD and GitHub Actions)

### 1.4 Target Users
- Developers building bootc images
- DevOps engineers reviewing CI/CD logs
- System administrators troubleshooting builds

---

## 2. Goals & Success Metrics

### 2.1 Primary Goals

| Goal | Metric | Target |
|------|--------|--------|
| Visual Appeal | Developer satisfaction rating | 4.5/5 |
| Information Clarity | Time to identify build status | < 5 seconds |
| Error Detection | Time to locate errors | < 5 seconds |
| Scannability | Lines of output (verbose mode) | ~50-100 lines |
| CI/CD Compatibility | JSON mode availability | 100% |

### 2.2 Success Criteria
- Logs clearly show build progress through 8 distinct phases
- Errors are immediately visible with context and suggestions
- Profile information is prominently displayed
- Build summary provides all key metrics at a glance
- System works with and without Gum installed (graceful fallback)

---

## 3. Functional Requirements

### 3.1 Log Levels

The system must support four log levels, controlled via `GUM_LOG_LEVEL` environment variable:

| Level | Description | Use Case |
|-------|-------------|----------|
| `debug` | All messages including detailed debug info | Troubleshooting, development |
| `info` | Info, warnings, and errors (DEFAULT) | Standard builds |
| `warn` | Warnings and errors only | Quiet monitoring |
| `error` | Errors only | Critical alerts only |

**Requirement ID**: FR-001
**Priority**: High

### 3.2 Visual Design System

#### 3.2.1 Color Palette

All colors optimized for dark terminal backgrounds:

| Purpose | Hex Code | Gum Usage |
|---------|----------|-----------|
| Debug | `#6B7280` | `--foreground` for debug messages |
| Info | `#3B82F6` | `--foreground` for info messages |
| Warning | `#F59E0B` | `--foreground` for warnings |
| Error | `#EF4444` | `--foreground` and `--border-foreground` for errors |
| Success | `#10B981` | `--foreground` for success states |
| Header | `#8B5CF6` | `--border-foreground` for header borders |
| Gold | `#FBBF24` | `--foreground` for timestamps and highlights |
| White | `#E5E7EB` | `--foreground` for body text |
| Dim | `#9CA3AF` | `--foreground` for secondary text |

**Requirement ID**: FR-002
**Priority**: High

#### 3.2.2 Emoji Indicators

| Emoji | Meaning | Usage Context |
|-------|---------|---------------|
| 🚀 | Build start | Header block |
| ✅ | Success/check | Completed items, success states |
| ⚠️ | Warning | Warning messages |
| ❌ | Error | Error messages, failed builds |
| ℹ️ | Info | Informational messages |
| ▶️ | Phase start | Phase headers |
| → | Detail arrow | Indented details |
| • | Bullet point | Lists within details |
| ⏱️ | Time/duration | Timestamps, durations |
| 📦 | Package | Package-related info |
| 🏷️ | Tags/labels | Image tags section |

**Requirement ID**: FR-003
**Priority**: High

### 3.3 Layout Structure

#### 3.3.1 Header Block

Must display at build start:
- Build started indicator with rocket emoji
- Double border with purple color
- Image name
- Profile name (e.g., "asus")
- Base image reference
- Timestamp with clock emoji

**Requirement ID**: FR-004
**Priority**: High

#### 3.3.2 Phase Structure

Each of the 8 phases must follow this pattern:

```
▶️ Phase X/8: [Phase Name]
  
  ✅ [Completed action]
    → [Detail item]
    → [Detail item]
    
  ✅ Phase complete in ⏱️ Xs
```

**Phases**:
1. Environment Preparation
2. System Overlay
3. Package Installation
4. COPR Repositories
5. Theming & Fonts
6. Service Configuration
7. Cleanup
8. Finalization

**Requirement ID**: FR-005
**Priority**: High

#### 3.3.3 Footer Block

Must display at build end:
- Success or failure status with appropriate emoji
- Double border with color matching status (green/red)
- Total duration with clock emoji
- Image size
- Number of layers
- Package statistics (installed/removed)
- List of generated image tags

**Requirement ID**: FR-006
**Priority**: High

### 3.4 Hierarchical Logging

Support three levels of indentation:

| Level | Indent | Icon | Usage |
|-------|--------|------|-------|
| 1 | 2 spaces | ✅ | Phase actions |
| 2 | 4 spaces | → | Details under actions |
| 3 | 6 spaces | • | Sub-lists |

**Requirement ID**: FR-007
**Priority**: Medium

### 3.5 Smart Filtering

#### 3.5.1 DNF5 Output Filtering

Must suppress the following DNF5 output patterns:
- Lines starting with `[` (progress indicators)
- "Copying blob" messages
- "Writing manifest" messages
- "100% |" progress lines
- "KiB/s" transfer rates
- "Complete!" messages

**Requirement ID**: FR-008
**Priority**: High

#### 3.5.2 Warning Suppression

Must track and suppress repeated warnings:
- Show first occurrence of each warning type
- Display count of suppressed warnings
- Indicate how to see full log (verbose flag)

**Requirement ID**: FR-009
**Priority**: Medium

### 3.6 Error Handling Display

When errors occur, must display:
- Red-bordered error block
- Phase and step where error occurred
- Error message
- Suggested fixes (bullet list)
- Duration until failure

**Requirement ID**: FR-010
**Priority**: High

---

## 4. Technical Architecture

### 4.1 Core Library (lib.sh)

**Location**: `files/scripts/lib.sh`

#### 4.1.1 Functions

| Function | Purpose | Parameters |
|----------|---------|------------|
| `log_init()` | Initialize logging configuration | None |
| `log_debug()` | Log debug message | Message string |
| `log_info()` | Log info message | Message string |
| `log_warn()` | Log warning message | Message string |
| `log_error()` | Log error message | Message string |
| `log_success()` | Log success message | Message string |
| `log_item()` | Generic item logger | Icon, message, indent |
| `log_detail()` | Log detail line | Message |
| `log_subdetail()` | Log sub-detail | Message |
| `log_check()` | Log checkmark item | Message |
| `start_phase()` | Start new phase | Phase name |
| `end_phase()` | End current phase | None |
| `print_header()` | Print build header | Image, profile, base |
| `print_footer()` | Print build footer | Duration, size, status |

**Requirement ID**: TA-001
**Priority**: High

#### 4.1.2 Fallback Mechanism

Every function must implement fallback logging when Gum is unavailable:
- Check `gum_available()` before using Gum commands
- Fall back to plain `echo` with bracketed log levels
- Maintain same message content in fallback mode

**Requirement ID**: TA-002
**Priority**: High

### 4.2 Configuration

#### 4.2.1 Environment Variables

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `GUM_LOG_LEVEL` | `info` | debug, info, warn, error | Controls verbosity |
| `GUM_LOG_FORMAT` | `text` | text, json | Output format |

**Requirement ID**: TA-003
**Priority**: High

#### 4.2.2 GitHub Actions Integration

Support GitHub Actions workflow commands:
- `::error::` annotations for errors
- `::warning::` annotations for warnings
- Maintain visual output alongside annotations

**Requirement ID**: TA-004
**Priority**: Medium

### 4.3 Gum Installation

Gum must be installed in the container image:
- Add `dnf5 install -y gum` to base.sh (Stage 1)
- Verify availability before first log call
- Document as build dependency

**Requirement ID**: TA-005
**Priority**: High

---

## 5. Non-Functional Requirements

### 5.1 Performance

| Requirement | Target |
|-------------|--------|
| Logging overhead | < 1% of build time |
| Memory usage | < 10MB for log buffering |
| Startup time | < 100ms for log initialization |

**Requirement ID**: NFR-001
**Priority**: Medium

### 5.2 Compatibility

| Platform | Support Level |
|----------|---------------|
| GitHub Actions | Full support (primary) |
| Local terminal | Full support |
| CI/CD systems | JSON mode for parsing |
| Minimal environments | Fallback mode |

**Requirement ID**: NFR-002
**Priority**: High

### 5.3 Maintainability

- Single source of truth: `lib.sh`
- Clear function naming conventions
- Consistent error handling
- Documented configuration options

**Requirement ID**: NFR-003
**Priority**: Medium

---

## 6. User Stories

### 6.1 Developer Reviewing Failed Build

**As a** developer
**I want** to immediately see what phase failed and why
**So that** I can quickly diagnose and fix issues

**Acceptance Criteria**:
- Error is visible within first 10 lines of log
- Phase number and name clearly shown
- Error message is descriptive
- Suggested fixes are provided

### 6.2 DevOps Engineer Monitoring CI/CD

**As a** DevOps engineer
**I want** to scan build logs quickly in GitHub Actions
**So that** I can verify builds are progressing normally

**Acceptance Criteria**:
- Each phase completion is clearly marked
- Progress indicators show package installation status
- Warnings are visible but not overwhelming
- Total build time is prominently displayed

### 6.3 System Administrator Troubleshooting

**As a** system administrator
**I want** detailed debug logs when needed
**So that** I can diagnose complex build issues

**Acceptance Criteria**:
- Debug mode shows all suppressed output
- Can enable via environment variable
- Debug logs don't clutter normal output

---

## 7. Implementation Plan

### 7.1 Phase 1: Core Library
- Create `lib.sh` with all logging functions
- Implement fallback mechanisms
- Add configuration variable support

### 7.2 Phase 2: Integration
- Install Gum in base.sh
- Update existing build scripts to use new logging
- Add header/footer calls to main build script

### 7.3 Phase 3: Filtering
- Implement DNF5 output filtering
- Add warning suppression logic
- Test with actual package installations

### 7.4 Phase 4: CI/CD
- Test in GitHub Actions workflow
- Verify JSON mode functionality
- Add GitHub Actions annotations

### 7.5 Phase 5: Documentation
- Update README with logging documentation
- Add troubleshooting guide
- Document configuration options

---

## 8. Testing Strategy

### 8.1 Unit Tests
- Test each logging function independently
- Verify fallback mechanisms
- Test log level filtering

### 8.2 Integration Tests
- Run full build with new logging
- Verify all 8 phases display correctly
- Test error scenarios

### 8.3 CI/CD Tests
- Run in GitHub Actions environment
- Verify output renders correctly
- Test JSON mode parsing

### 8.4 Visual Regression
- Capture expected output for each phase
- Compare against actual output
- Verify color codes and formatting

---

## 9. Open Questions

1. Should we support custom color schemes via environment variables?
2. Do we need to support light terminal backgrounds?
3. Should we add a "dry run" mode that shows what would be logged?
4. Do we need to persist logs to a file alongside terminal output?

---

## 10. Appendix

### 10.1 Example Build Log Output

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   🚀  BUILD STARTED                                             │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                                                 │
│   Image:    mina-fedora-atomic-desktop:latest                  │
│   Profile:  asus                                                │
│   Base:     ghcr.io/ublue-os/base-main:43                      │
│   Started:  ⏱️ 2026-02-18 14:32:15                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

▶️ Phase 1/8: Environment Preparation
  
  ✅ Creating directory structure
    → /var/roothome
    → /var/lib/alternatives  
    → /etc/environment.d
    
  ✅ Setting up environment variables
    → HOST_PROFILE=asus
    → IMAGE_NAME=mina-fedora-atomic-desktop
    
  ✅ Phase complete in ⏱️ 0.8s

▶️ Phase 2/8: System Overlay

  ✅ Copying system files
    → 47 files copied to /etc
    → 12 files copied to /usr/lib
    
  ✅ Applying permissions
    → SSH configuration secured
    → Greetd configuration applied
    → Bootc kernel arguments set
    
  ✅ Phase complete in ⏱️ 1.2s

[... phases 3-7 ...]

▶️ Phase 8/8: Finalization

  ✅ Running bootc container lint
  ✅ Creating image tags
    → latest
    → latest.20260218
    → 20260218
    
  ✅ Phase complete in ⏱️ 3.2s

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   ✅  BUILD SUCCESSFUL                                          │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                                                 │
│   Duration:     ⏱️ 3m 42s                                       │
│   Image Size:   4.7 GB                                          │
│   Layers:       9                                               │
│   Packages:     447 installed, 22 removed                       │
│                                                                 │
│   🏷️  Tags:                                                      │
│   → mina-fedora-atomic-desktop:latest                          │
│   → mina-fedora-atomic-desktop:latest.20260218                 │
│   → mina-fedora-atomic-desktop:20260218                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 10.2 Configuration Examples

**Debug Mode**:
```bash
export GUM_LOG_LEVEL=debug
./build.sh
```

**JSON Mode for CI**:
```bash
export GUM_LOG_LEVEL=info
export GUM_LOG_FORMAT=json
./build.sh
```

**Quiet Mode**:
```bash
export GUM_LOG_LEVEL=warn
./build.sh
```

---

**End of PRD**
