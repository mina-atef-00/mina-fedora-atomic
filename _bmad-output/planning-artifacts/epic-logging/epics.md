---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories']
inputDocuments:
  - _bmad-output/planning-artifacts/gum-logging-prd.md
  - _bmad-output/planning-artifacts/architecture.md
---

# Gum-Based Logging System - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for the Gum-Based Logging System, decomposing the requirements from the PRD and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR-001: Support four log levels (debug, info, warn, error) controlled via GUM_LOG_LEVEL environment variable

FR-002: Implement color palette optimized for dark terminal backgrounds with specific hex codes for Debug (#6B7280), Info (#3B82F6), Warning (#F59E0B), Error (#EF4444), Success (#10B981), Header (#8B5CF6), Gold (#FBBF24), White (#E5E7EB), and Dim (#9CA3AF)

FR-003: Use emoji indicators for visual communication: 🚀 (build start), ✅ (success), ⚠️ (warning), ❌ (error), ℹ️ (info), ▶️ (phase start), → (detail arrow), • (bullet), ⏱️ (time), 📦 (package), 🏷️ (tags)

FR-004: Display header block at build start with build indicator, double border, image name, profile name, base image reference, and timestamp

FR-005: Display build phases dynamically based on Containerfile RUN layers with consistent structure

FR-006: Display footer block at build end with success/failure status, duration, image size, layers, package statistics, and image tags

FR-007: Support three levels of hierarchical logging with 2-space indentation for phase actions, 4-space for details, and 6-space for sub-lists

FR-008: Filter DNF5 output to suppress progress indicators, blob copying, manifest writing, percentage lines, transfer rates, and completion messages

FR-009: Track and suppress repeated warnings, showing first occurrence with count and verbose flag indicator

FR-010: Display errors with red-bordered block, phase/step location, error message, suggested fixes, and duration until failure

### Non-Functional Requirements

NFR-001: Performance targets - Logging overhead < 1% of build time, Memory usage < 10MB for log buffering, Startup time < 100ms for log initialization

NFR-002: Compatibility requirements - Full support for GitHub Actions (primary), Local terminal, CI/CD systems with JSON mode, Minimal environments with fallback mode

NFR-003: Maintainability requirements - Single source of truth (lib.sh), Clear function naming conventions, Consistent error handling, Documented configuration options

### Additional Requirements

- **Technology Stack**: Bash-based modular system using Charmbracelet Gum for terminal styling
- **Infrastructure**: Must work within Fedora Atomic/bootc container build system
- **Integration**: GitHub Actions workflow integration with ::error:: and ::warning:: annotations
- **Fallback**: Graceful degradation to plain echo when Gum is unavailable
- **Location**: Core library at `files/scripts/lib.sh`
- **Installation**: Gum installed via `dnf5 install -y gum` in base.sh (Stage 1)
- **Configuration**: Environment variables GUM_LOG_LEVEL (default: info) and GUM_LOG_FORMAT (default: text)

### FR Coverage Map

(To be populated after epic design)

## Epic List

## Epic List

### Epic 1: Epic Logging
Enable developers, DevOps engineers, and system administrators to have clear, beautiful, and informative build logs that make troubleshooting and monitoring bootc image builds efficient and pleasant.

**FRs covered:** FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010
**NFRs covered:** NFR-001, NFR-002, NFR-003

### FR Coverage Map

| FR | Story | Description |
|----|-------|-------------|
| FR-001 | Story 1.1 | Log levels (debug, info, warn, error) |
| FR-002 | Story 1.2 | Color palette for dark terminals |
| FR-003 | Story 1.2 | Emoji indicators |
| FR-004 | Story 1.1 | Header block with build info |
| FR-005 | Story 1.1 | Phase structure (dynamic based on Containerfile layers) |
| FR-006 | Story 1.1 | Footer block with summary |
| FR-007 | Story 1.5 | Hierarchical logging (3 levels) |
| FR-008 | Story 1.3 | DNF5 output filtering |
| FR-009 | Story 1.3 | Warning suppression |
| FR-010 | Story 1.3 | Error display with fixes |

<!-- Epic 1 Section -->

## Epic 1: Epic Logging

Enable developers, DevOps engineers, and system administrators to have clear, beautiful, and informative build logs that make troubleshooting and monitoring bootc image builds efficient and pleasant.

### Stories

#### Story 1.1: Core Logging Library with Gum Integration

As a developer,
I want a logging library with configurable levels and Gum support,
So that I can add structured logging to my build scripts with beautiful terminal output.

**Acceptance Criteria:**

**Given** the logging library is initialized
**When** `GUM_LOG_LEVEL` is set to `info` (default)
**Then** only info, warning, and error messages are displayed
**And** debug messages are suppressed

**Given** Gum is not installed on the system
**When** logging functions are called
**Then** the library falls back to plain `echo` output
**And** messages still include log level prefixes (e.g., "[INFO]", "[ERROR]")

**Given** the build process starts
**When** `print_header()` is called
**Then** it displays a beautifully formatted header with 🚀 emoji
**And** includes image name, profile, base reference, and timestamp
**And** uses double border styling with purple (#8B5CF6) color

**Given** the build process completes
**When** `print_footer()` is called with success status
**Then** it displays a green-bordered footer with ✅ emoji
**And** includes duration, image size, layers, packages, and tags

**Given** a build phase begins
**When** `start_phase()` is called with phase name
**Then** it displays ▶️ Phase header with rounded border
**And** uses blue (#3B82F6) color for the phase indicator

**Given** a build phase completes
**When** `end_phase()` is called
**Then** it displays ✅ Phase complete with ⏱️ duration
**And** uses green (#10B981) color for success indicator

**Given** the Containerfile has multiple RUN stages
**When** each RUN stage executes
**Then** phases are dynamically created based on layer count
**And** phase numbering adapts to total number of layers

---

#### Story 1.2: Visual Design System Implementation

As a DevOps engineer,
I want logs with consistent colors and emojis,
So that I can quickly scan and understand build status at a glance.

**Acceptance Criteria:**

**Given** a debug message is logged
**When** `log_debug()` is called
**Then** the message displays in gray (#6B7280) color
**And** includes appropriate emoji if applicable

**Given** an info message is logged
**When** `log_info()` is called
**Then** the message displays in blue (#3B82F6) color
**And** includes ℹ️ emoji prefix

**Given** a warning message is logged
**When** `log_warn()` is called
**Then** the message displays in amber (#F59E0B) color
**And** includes ⚠️ emoji prefix

**Given** an error message is logged
**When** `log_error()` is called
**Then** the message displays in red (#EF4444) color with bold formatting
**And** includes ❌ emoji prefix

**Given** a success message is logged
**When** `log_success()` is called
**Then** the message displays in green (#10B981) color with bold formatting
**And** includes ✅ emoji prefix

**Given** hierarchical logging is used
**When** `log_item()`, `log_detail()`, or `log_subdetail()` is called
**Then** each level uses appropriate indentation (2, 4, or 6 spaces)
**And** uses correct icon (✅, →, or •) for each level

---

#### Story 1.3: Smart Output Filtering and Error Handling

As a system administrator,
I want verbose output filtered and errors clearly displayed,
So that logs stay concise while critical issues are immediately visible.

**Acceptance Criteria:**

**Given** DNF5 is installing packages
**When** progress indicators appear (lines starting with `[`)
**Then** they are suppressed from the log output
**And** only package installation summaries are shown

**Given** DNF5 outputs "Copying blob" messages
**When** these messages appear
**Then** they are filtered out entirely
**And** not displayed in the log

**Given** DNF5 outputs "Writing manifest" messages
**When** these messages appear
**Then** they are filtered out entirely

**Given** DNF5 shows "100% |" progress lines
**When** these appear during package download
**Then** they are suppressed
**And** only final completion is shown

**Given** DNF5 shows transfer rates ("KiB/s")
**When** these appear
**Then** they are filtered out

**Given** DNF5 outputs "Complete!" messages repeatedly
**When** these appear for each package
**Then** only the first occurrence is shown
**And** subsequent occurrences are counted and summarized

**Given** a warning appears multiple times
**When** the same warning type is encountered
**Then** only the first instance is displayed
**And** a count of suppressed warnings is shown (e.g., "⚠️  5 similar warnings suppressed")
**And** the message indicates how to see all warnings (--verbose flag)

**Given** a build error occurs
**When** `log_error()` is called with error details
**Then** a red-bordered error block is displayed
**And** includes current phase name and step
**And** shows descriptive error message
**And** lists suggested fixes as bullet points (→)
**And** displays duration until failure with ⏱️ emoji

**Given** a critical error occurs during package installation
**When** the error is logged
**Then** GitHub Actions annotations are generated (`::error::`)
**And** visual error block is still displayed in terminal

**Given** a warning is logged in CI environment
**When** `log_warn()` is called
**Then** GitHub Actions annotations are generated (`::warning::`)
**And** visual warning is displayed in terminal

---

#### Story 1.4: GitHub Actions Integration and JSON Mode

As a DevOps engineer,
I want logs compatible with GitHub Actions and JSON output support,
So that CI/CD pipelines can parse and process build logs programmatically.

**Acceptance Criteria:**

**Given** `GUM_LOG_FORMAT` is set to `json`
**When** any log function is called
**Then** output is valid JSON format
**And** includes timestamp, level, message, and metadata fields

**Given** JSON mode is enabled
**When** a phase starts
**Then** JSON output includes phase number, name, and timestamp

**Given** JSON mode is enabled
**When** an error occurs
**Then** JSON output includes error details, phase, and suggested fixes

**Given** running in GitHub Actions environment
**When** `log_error()` is called
**Then** `::error file=Containerfile,line=1::message` is output
**And** JSON/text output is also generated based on GUM_LOG_FORMAT

**Given** running in GitHub Actions environment
**When** `log_warn()` is called
**Then** `::warning file=Containerfile,line=1::message` is output

**Given** `GUM_LOG_LEVEL` is set to `debug`
**When** verbose logging is requested
**Then** all suppressed DNF5 output is shown
**And** warning deduplication is disabled
**And** full package installation details are visible

**Given** `GUM_LOG_LEVEL` is set to `warn`
**When** quiet monitoring is needed
**Then** only warnings and errors are displayed
**And** info messages are suppressed

**Given** `GUM_LOG_LEVEL` is set to `error`
**When** critical monitoring is needed
**Then** only errors are displayed
**And** all other messages are suppressed

---

#### Story 1.5: Hierarchical Logging and Detail Management

As a developer,
I want structured hierarchical logging with multiple detail levels,
So that I can organize log output logically and control verbosity.

**Acceptance Criteria:**

**Given** `log_item()` is called with message and indent level
**When** displaying phase actions (level 1)
**Then** output is indented 2 spaces from left margin
**And** uses ✅ icon prefix

**Given** `log_detail()` is called
**When** displaying details under actions (level 2)
**Then** output is indented 4 spaces from left margin
**And** uses → icon prefix
**And** uses white (#E5E7EB) color for text

**Given** `log_subdetail()` is called
**When** displaying sub-lists (level 3)
**Then** output is indented 6 spaces from left margin
**And** uses • icon prefix
**And** uses dim (#9CA3AF) color for secondary text

**Given** `log_check()` is called
**When** marking items as completed
**Then** output is indented 2 spaces
**And** uses ✅ icon in green (#10B981) color
**And** text is descriptive of the completed action

**Given** multiple levels are used in sequence
**When** parent → child → grandchild structure is created
**Then** indentation is consistent (2→4→6 spaces)
**And** visual hierarchy is clear and scannable

---

#### Story 1.6: Library Integration and Build Script Updates

As a maintainer,
I want the logging library integrated into existing build scripts,
So that all builds use the new logging system consistently.

**Acceptance Criteria:**

**Given** the base.sh script runs
**When** Stage 1 (early setup) executes
**Then** `dnf5 install -y gum` is called
**And** installation failure is handled gracefully with fallback

**Given** lib.sh is created at `files/scripts/lib.sh`
**When** build scripts source the library
**Then** all logging functions are available
**And** `log_init()` initializes configuration

**Given** existing build scripts exist
**When** they are updated to use lib.sh
**Then** `source /ctx/files/scripts/lib.sh` is added
**And** `print_header()` is called at build start
**And** `print_footer()` is called at build end

**Given** Containerfile RUN stages execute
**When** each layer builds
**Then** `start_phase()` is called with layer-appropriate name
**And** `end_phase()` is called at layer completion
**And** phase names map to Containerfile layer purposes

**Given** the main build entry point runs
**When** build starts
**Then** header displays within first 100ms
**And** phases progress sequentially
**And** footer displays final status

**Given** a build completes successfully
**When** footer is displayed
**Then** all metrics are accurate (duration, size, packages, tags)
**And** tags include :latest, :latest.DATE, :DATE formats
