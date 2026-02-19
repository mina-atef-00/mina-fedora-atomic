---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics']
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

FR-005: Display 8 build phases (Environment Preparation, System Overlay, Package Installation, COPR Repositories, Theming & Fonts, Service Configuration, Cleanup, Finalization) with consistent structure

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

| FR | Description |
|----|-------------|
| FR-001 | Epic 1 - Log levels (debug, info, warn, error) |
| FR-002 | Epic 1 - Color palette for dark terminals |
| FR-003 | Epic 1 - Emoji indicators |
| FR-004 | Epic 1 - Header block with build info |
| FR-005 | Epic 1 - 8-phase structure |
| FR-006 | Epic 1 - Footer block with summary |
| FR-007 | Epic 1 - Hierarchical logging (3 levels) |
| FR-008 | Epic 1 - DNF5 output filtering |
| FR-009 | Epic 1 - Warning suppression |
| FR-010 | Epic 1 - Error display with fixes |

<!-- Epic 1 Section -->

## Epic 1: Epic Logging

Enable developers, DevOps engineers, and system administrators to have clear, beautiful, and informative build logs that make troubleshooting and monitoring bootc image builds efficient and pleasant.

### Stories

(To be created in step 3)
