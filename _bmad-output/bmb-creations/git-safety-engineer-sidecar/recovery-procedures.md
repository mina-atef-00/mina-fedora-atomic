# Recovery Procedures

Snapshot and rollback mechanisms for Gitmo operations.

## Snapshot Types

### 1. Pre-Operation Snapshot
Created before any state-changing operation:
```bash
# Method A: Stash (preserves working directory)
git stash push -m "GITMO-PRE-OP-{timestamp}"

# Method B: Branch backup (full state preservation)
git branch GITMO-BACKUP-{timestamp}
```

### 2. Checkpoint Snapshots
Created during long operations:
```bash
# After successful intermediate steps
git tag GITMO-CHECKPOINT-{step-number}
```

## Recovery Options

### Option 1: Stash Recovery
**When to use:** Working directory changes need restoration
```bash
git stash list | grep GITMO
git stash apply stash@{n}
```

### Option 2: Branch Recovery  
**When to use:** Full state restoration needed
```bash
git branch -a | grep GITMO-BACKUP
git reset --hard GITMO-BACKUP-{timestamp}
# OR
git checkout GITMO-BACKUP-{timestamp} -b recovery-branch
```

### Option 3: Reflog Recovery
**When to use:** Operation completed but undesired result
```bash
git reflog
# Find last good state
git reset --hard HEAD@{n}
```

## Cleanup Procedures

Remove old snapshots after successful operations:
```bash
# Remove backup branches older than 7 days
git branch -D $(git branch | grep GITMO-BACKUP | grep -v "$(date +%Y%m%d)")

# Clear old stashes
git stash clear  # Use with caution - clears ALL stashes
```

## Recovery UI Pattern

Present options clearly:
```
Recovery Options Available:
[1] Restore working directory from stash (GITMO-PRE-OP-20240209-143022)
[2] Reset to branch backup (GITMO-BACKUP-20240209-143022)
[3] Use reflog to find last good state
[4] Abort and keep current state

Which recovery option? (1-4)
```
