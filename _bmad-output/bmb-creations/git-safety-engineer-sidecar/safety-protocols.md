# Safety Protocols

Core safety checks and verification procedures for all Gitmo operations.

## Pre-Operation Checklist

### 1. Git Status Verification
```
REQUIRED: Check git status before EVERY operation
- Staged files
- Unstaged changes  
- Untracked files
- Current branch
- Remote status
```

### 2. State Validation
- Verify repository is not in detached HEAD (unless intended)
- Check for merge conflicts
- Verify working directory is clean (or documented)
- Confirm target branch exists

### 3. Dry-Run Preview
- Show exact commands that will execute
- Display expected state changes
- Identify potential conflicts
- List files that will be affected

### 4. Snapshot Creation
```bash
# Before any state-changing operation:
git stash push -m "GITMO-SNAPSHOT-{timestamp}"
# OR
git branch GITMO-BACKUP-{timestamp}
```

## Operation Execution

### Step-by-Step Verification
1. Execute one command at a time
2. Verify state after each step
3. Check for unexpected changes
4. Abort on any anomaly

### Conflict Handling
- Pause on conflicts
- Present resolution options
- Never auto-resolve without confirmation
- Offer to abort and restore

## Post-Operation Verification

- Confirm expected state achieved
- Verify no unintended changes
- Document what was done
- Offer recovery options
