# Intent Parser

Natural language intent parsing and disambiguation for Gitmo.

## Intent Categories

### Split Commits
**Triggers:** "split", "break apart", "separate", "organize commits"
**Action:** Analyze staged/unstaged changes and suggest logical groupings
**Clarification Needed:**
- How many commits? (auto-detect if not specified)
- Grouping criteria? (file type, logical change, etc.)

### Safe Rebase
**Triggers:** "rebase", "rebase onto", "replay commits"
**Action:** Create snapshot, plan rebase, preview conflicts
**Clarification Needed:**
- Target branch? (default: main/master)
- Interactive or standard?

### Conventional Commits
**Triggers:** "conventional commit", "format commit", "proper commit"
**Action:** Auto-categorize changes and format commit message
**Clarification Needed:**
- Commit type? (feat, fix, docs, etc. - auto-detect if not specified)
- Breaking change?

### Undo Operation
**Triggers:** "undo", "revert", "go back", "restore"
**Action:** Show recent operations and recovery options
**Clarification Needed:**
- Which operation to undo?
- Hard or soft recovery?

### Move to Branch
**Triggers:** "move to branch", "carry changes", "switch branch with changes"
**Action:** Stash/save changes, checkout target, apply safely
**Clarification Needed:**
- Target branch name?
- Create new branch?

### Clean History
**Triggers:** "clean history", "reorganize", "squash", "reword"
**Action:** Analyze history and suggest reorganization
**Clarification Needed:**
- How many commits to affect?
- What outcome desired?

### Cherry-Pick
**Triggers:** "cherry-pick", "apply commit", "copy commit"
**Action:** Select commits and apply with dependency checking
**Clarification Needed:**
- Which commits? (hash or reference)
- Any specific order?

## Disambiguation Strategy

When intent is unclear:
1. Ask clarifying questions
2. Present 2-3 most likely interpretations
3. Request user selection
4. Never guess on ambiguous operations

## Confirmation Pattern

Always confirm understanding:
"I understand you want to [action]. This will [effect]. Proceed?"
