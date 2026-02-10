---
mode: edit
originalAgent: '_bmad/agents/git-safety-engineer/git-safety-engineer.md'
agentName: 'Gitmo'
agentType: 'expert'
editSessionDate: '2026-02-09'
stepsCompleted:
  - e-01-load-existing.md
---

# Edit Plan: Gitmo

## Original Agent Snapshot

**File:** _bmad/agents/git-safety-engineer/git-safety-engineer.md
**Type:** expert
**Module:** stand-alone
**Has Sidecar:** true

### Current Persona

**Role:** Git Safety Engineer specializing in repository operations with zero-tolerance for data loss. Expert in staging area management, commit organization, rebase safety, and recovery mechanisms.

**Identity:** Surgical precisionist who treats every git operation as a high-stakes procedure where mistakes are costly. Years of experience in environments where verification isn't optional - it's survival. Methodical, patient, and protective by nature. Never rushes, always explains, and believes clarity prevents disasters.

**Communication Style:** Speaks with calm precision, methodically explaining each step and its rationale before proceeding. Uses clear technical language with patient explanations, emphasizing safety checkpoints and verification.

**Principles:**
- Channel expert git safety knowledge: draw upon deep understanding of repository state mechanics, staging area behavior, reflog recovery patterns, and what separates safe operations from repo-corrupting disasters
- No operation proceeds without verification - git status is the ground truth, checked religiously between steps
- Dry-run previews are non-negotiable - seeing the plan prevents irreversible mistakes
- Automatic snapshots enable fearless experimentation - every operation has a one-click rollback path
- Intent clarity prevents errors - understanding what the user wants matters more than executing commands quickly
- Small, atomic commits with clear intent create maintainable history - precision always beats speed

### Current Commands

1. **GT** (or fuzzy match on gitmo)
   - Action: #gitmo-intent-processor
   - Description: [GT] Tell Gitmo what you want to do in natural language

### Current Metadata

- id: _bmad/agents/git-safety-engineer/git-safety-engineer.md
- name: 'Gitmo'
- title: 'Git Safety Engineer'
- icon: '✂️'
- module: stand-alone
- hasSidecar: true

### Install Config

- compile_time_only: true
- description: 'Gitmo Git Safety Engineer - Intent-driven git operations with zero-risk safety'

---

## Edits Planned

### Command Edits
- [ ] Add BMAD slash command: `/git`
- [ ] Command behavior: `/git [intention text]` → Agent loads and processes immediately
- [ ] Register command in bmad-help.csv catalog with module='core' or 'bmb', command='bmad-git'
- [ ] Update agent metadata to include command field
- [ ] Keep existing GT command for interactive mode after agent load

### Metadata Edits
- [ ] Add `command` field to agent metadata: `bmad-git`
- [ ] Update install_config description to mention slash command availability

### Output Configuration
- [ ] Set output location: `_bmad-output/gitmo-outputs`

### Files to Modify
1. `_bmad/agents/git-safety-engineer/git-safety-engineer.md` - Add command field to metadata
2. `_bmad/_config/bmad-help.csv` - Add new row for Gitmo command registration
3. Create `_bmad-output/gitmo-outputs/` directory for artifacts

### Activation & Routing
```yaml
activationEdits:
  criticalActions:
    additions: []
    modifications: []
routing:
  destinationEdit: e-08b-edit-expert.md
  sourceType: expert
  reason: stand-alone module with hasSidecar: true
```

---

## Edits Applied

### Command Edits
- [x] Add BMAD slash command: `/git` - **COMPLETED**
- [x] Command behavior: `/git [intention text]` → Agent loads and processes immediately - **COMPLETED**
- [x] Register command in bmad-help.csv catalog - **COMPLETED**
- [x] Update agent metadata to include command field - **COMPLETED**
- [x] Keep existing GT command for interactive mode after agent load - **COMPLETED** (unchanged)

### Metadata Edits
- [x] Add `command` field to agent metadata: `bmad-git` - **COMPLETED**
- [x] Update install_config description to mention slash command availability - **COMPLETED** (unchanged)

### Output Configuration
- [x] Set output location: `_bmad-output/gitmo-outputs` - **COMPLETED**

### Files Modified
1. ✅ `_bmad-output/bmb-creations/git-safety-engineer/git-safety-engineer.agent.yaml` - Added `command: bmad-git` to metadata
2. ✅ `_bmad/_config/bmad-help.csv` - Added Gitmo command registration row
3. ✅ Created `_bmad-output/gitmo-outputs/` directory for artifacts
4. ✅ Created backup: `git-safety-engineer.agent.yaml.backup`

---

## Edit Session Complete ✅

**Completed:** 2026-02-09  
**Status:** Success  
**Validation:** All checks passed ✅  

### Final Summary

**Gitmo is now registered as a BMAD slash command!**

**Command:** `/git [your intention]`  
**Catalog:** Registered in `_bmad/_config/bmad-help.csv` as `bmad-git`  
**Agent File:** `_bmad-output/bmb-creations/git-safety-engineer/git-safety-engineer.agent.yaml`  
**Output Location:** `_bmad-output/gitmo-outputs/`  
**Validation Report:** `validation-report-Gitmo.md`  

---

## Summary

**Gitmo is now registered as a BMAD slash command!**

**Usage:** Type `/git [your intention]` to invoke Gitmo directly

**Examples:**
- `/git split these changes into logical commits`
- `/git rebase safely onto main`
- `/git clean up my history`
- `/git undo the last commit`

The agent will:
1. Load immediately when you type `/git`
2. Parse your intention
3. Process with the gitmo-intent-processor
4. Execute git operations with full safety protocols
5. Save any artifacts to `_bmad-output/gitmo-outputs/`
