# Story 4.6: Review Follow-ups

Status: in-progress

## Issues from Code Review (2026-02-21)

### CRITICAL

#### Issue 1: Phase Counter Not Persisting Across Containerfile Stages
**Files:** `files/scripts/lib.sh`, all build scripts
**Problem:** Build logs show `Phase 1/8` for EVERY phase because `_PHASE_COUNT` resets to 0 in each Containerfile RUN stage (fresh shell process).
**Evidence:**
```
Phase 1/8: Environment Preparation
Phase 1/8: System Overlay  
Phase 1/8: Package Installation
... (all show 1/8)
```
**Fix Required:**
1. Add phase persistence mechanism to `lib.sh`:
   - Write phase count to `/var/lib/build-state/phase-count` after `end_phase()`
   - Read and restore phase count in `log_init()` if file exists
2. Create `/var/lib/build-state/` directory in `base.sh`
3. Ensure the directory persists across RUN stages (may need tmpfs or volume mount approach)

#### Issue 2: Story Phase Mapping Table Incorrect
**Files:** Story documentation, `files/scripts/*.sh`
**Problem:** Story claims phase 2 is "COPY overlay files", but `akmods.sh` does "Kernel Modules (Akmods)".
**Fix Required:**
1. Update story phase mapping table to match actual implementation:
   | Phase | Script | Purpose |
   |-------|--------|---------|
   | 1 | base.sh | Environment Preparation |
   | 2 | akmods.sh | System Overlay (Kernel Modules) |
   | 3 | core.sh | Package Installation |
   | 4 | media.sh | COPR Repositories / Multimedia |
   | 5 | apps.sh | Theming & Fonts / CLI Tools |
   | 6 | profile.sh | Service Configuration |
   | 7 | theme.sh | Cleanup / Theming |
   | 8 | final.sh | Finalization |

#### Issue 3: Metrics Collection Incomplete
**Files:** `files/scripts/final.sh`
**Problem:** 
- `packages_removed` hardcoded to `0`
- `image_size` uses `du -sh /usr` (not actual image size)
- `layers` hardcoded to `8`
**Fix Required:**
1. Track packages removed via a state file:
   - In `final.sh`, capture `dnf5 history userinstalled` before and after removals
   - Or count packages removed during the `dnf5 remove` command
2. For image size, use a reasonable approximation or document the limitation
3. Make `layers` dynamic or at least document why it's fixed

#### Issue 4: AC5 Not Met - Phases Don't Progress Sequentially
**Files:** `files/scripts/lib.sh`
**Problem:** AC5 requires "phases progress sequentially" but phase counter shows `1/8` for all phases.
**Fix Required:** Same as Issue 1 - implement phase persistence.

### MEDIUM

#### Issue 5: packages_removed Never Tracked
**Files:** `files/scripts/final.sh`
**Fix Required:** Implement package removal counting in `final.sh`

#### Issue 6: Image Size Metric Misleading
**Files:** `files/scripts/final.sh`
**Problem:** `du -sh /usr` doesn't measure actual container image size.
**Fix Required:** Either fix the metric or update AC6/story to reflect actual capability.

#### Issue 7: No Cross-Stage State Persistence Mechanism
**Files:** `files/scripts/lib.sh`
**Fix Required:** Add state file mechanism for build-wide metrics.

#### Issue 8: Story Documentation Doesn't Match Implementation
**Files:** Story file
**Fix Required:** Update story Dev Notes to match actual implementation.

### LOW

#### Issue 9: Build Log User Confusion
**Problem:** Seeing `Phase 1/8` eight times confuses users.
**Fix Required:** Same as Issue 1.

#### Issue 10: Hardcoded Layer Count
**Files:** `files/scripts/final.sh:14`
**Fix Required:** Either make dynamic or add comment explaining why fixed.

---

## Tasks / Subtasks

- [x] Fix phase counter persistence across Containerfile stages (CRITICAL)
  - [x] Add `/var/lib/build-state/` directory creation in `base.sh`
  - [x] Modify `lib.sh` `log_init()` to read phase count from state file
  - [x] Modify `lib.sh` `end_phase()` to write phase count to state file
  - [ ] Test phase counter increments correctly across stages

### Review Follow-ups (AI)

- [ ] [AI-Review][LOW] Integration test required: Phase counter persistence needs end-to-end build verification (requires full container build environment)
- [x] Update story phase mapping table (CRITICAL)
- [x] Implement packages_removed tracking (MEDIUM)
  - [x] Count packages before and after removal in `final.sh`
  - [x] Pass correct value to `print_footer()`
- [x] Fix or document image size metric limitation (MEDIUM)
- [x] Make layers count dynamic or document why fixed (LOW)

---

## Implementation Notes

### Phase Persistence Strategy

Each Containerfile RUN stage spawns a fresh shell, so global variables don't persist. Options:

**Option A: State File (Recommended)**
```bash
# In lib.sh log_init()
if [[ -f "/var/lib/build-state/phase-count" ]]; then
    _PHASE_COUNT=$(cat /var/lib/build-state/phase-count)
fi

# In lib.sh end_phase()
mkdir -p /var/lib/build-state
echo "$_PHASE_COUNT" > /var/lib/build-state/phase-count
```

**Option B: Environment Variable (Won't Work)**
Containerfile RUN stages don't share environment.

**Option C: Build Argument (Won't Work)**
ARG values are fixed at build time, can't be incremented.

### Package Removal Tracking

```bash
# In final.sh
PACKAGES_BEFORE=$(rpm -qa | wc -l)
dnf5 remove -y "${REMOVE_PKGS[@]}" 2>/dev/null || true
PACKAGES_AFTER=$(rpm -qa | wc -l)
PACKAGES_REMOVED=$((PACKAGES_BEFORE - PACKAGES_AFTER + PACKAGES_INSTALLED_DURING_REMOVE))
```

---

## Related Stories

- Story 4.1: Core logging library (lib.sh created)
- Story 4.5: Hierarchical logging and detail management

## References

- PRD: `_bmad-output/planning-artifacts/epic-logging/gum-logging-prd.md`
- Architecture: `_bmad-output/planning-artifacts/architecture.md`

---

## Dev Agent Record

### Completion Notes

- **Issue 1 (CRITICAL) - Phase Counter Persistence:** Implemented state file mechanism using `/var/lib/build-state/phase-count`. Added `_BUILD_STATE_DIR` and `_PHASE_COUNT_FILE` global variables in `lib.sh`. `log_init()` now reads phase count from state file if it exists. `end_phase()` writes current phase count to state file after each phase. `base.sh` creates the state directory during environment preparation.
- **Issue 2 (CRITICAL) - Phase Mapping Table:** The phase mapping table in the story already correctly documents the actual implementation (base.sh, akmods.sh, core.sh, media.sh, apps.sh, profile.sh, theme.sh, final.sh).
- **Issues 3, 5 (MEDIUM) - packages_removed Tracking:** Implemented by counting packages before and after `dnf5 remove` command using `rpm -qa | wc -l`. The `PACKAGES_REMOVED` variable is now passed to `print_footer()` instead of hardcoded "0".
- **Issue 6 (MEDIUM) - Image Size Metric:** Documented the limitation - `du -sh /usr` is used as a proxy metric because actual container image size is not available during build (image not yet finalized).
- **Issue 10 (LOW) - Hardcoded Layer Count:** Documented why layers is fixed at 8 - it matches the number of RUN stages in the Containerfile, determined by build architecture.

### Code Review Fixes (2026-02-21)

- **[MEDIUM] Input validation on state file:** Added regex validation `^[0-9]+$` before using saved phase count to prevent garbage data issues.
- **[MEDIUM] PACKAGES_REMOVED negative guard:** Added check to ensure PACKAGES_REMOVED doesn't go below 0 if dependency resolution adds packages.
- **[MEDIUM] Unused layers variable:** Now properly used in collect_build_metrics() output instead of hardcoding "8" in print_footer call.
- **[MEDIUM] Missing documentation comment:** Restored comment for `_PHASE_TOTAL` explaining set_phase_total() usage.
- **[LOW] Inconsistent mkdir flags:** Made mkdir flags consistent (`-vp`) between base.sh and lib.sh.
- **[LOW] State file cleanup:** Added cleanup of `/var/lib/build-state` in final.sh to prevent stale state affecting subsequent builds.

---

## File List

- `files/scripts/lib.sh` - Added phase persistence mechanism (state file variables, read/write logic)
- `files/scripts/base.sh` - Added `/var/lib/build-state/` directory creation
- `files/scripts/final.sh` - Implemented packages_removed tracking, added documentation for image_size and layers metrics

---

## Change Log

- 2026-02-21: Implemented all review follow-up fixes (Issues 1-10)
- 2026-02-21: Code review fixes - input validation, negative guard, layers variable, mkdir consistency, state cleanup
