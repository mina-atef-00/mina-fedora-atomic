---
stepsCompleted: ['step-01-validate-prerequisites']
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

(To be designed in step 2)
