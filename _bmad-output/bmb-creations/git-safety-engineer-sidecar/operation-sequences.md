# Operation Sequences

Complex multi-step git operations for Gitmo.

## Conventional Commit Sequence

```
1. Check git status
2. Identify changed files
3. Categorize changes:
   - feat: new features
   - fix: bug fixes  
   - docs: documentation
   - style: formatting
   - refactor: code restructuring
   - test: tests
   - chore: maintenance
4. Suggest commit message
5. Preview staged changes
6. Create pre-commit snapshot
7. Stage files (if needed)
8. Execute commit
9. Verify commit created
```

## Split Commit Sequence

```
1. Check git status
2. Analyze all changes
3. Identify logical groupings
4. Present grouping options
5. User confirms groupings
6. Create snapshot
7. For each group:
   a. Stage specific files
   b. Create commit
   c. Verify commit
8. Final verification
```

## Safe Rebase Sequence

```
1. Check current branch and status
2. Identify target branch
3. Check for unpushed commits
4. Create backup branch
5. Fetch latest target branch
6. Preview rebase (dry-run)
7. Show potential conflicts
8. User confirmation
9. Execute rebase step-by-step
10. Handle any conflicts
11. Verify successful rebase
```

## Move Changes to Branch Sequence

```
1. Check current status
2. Identify changes to move
3. Create stash with changes
4. Checkout target branch
5. Apply stash
6. Handle conflicts if any
7. Verify changes applied
8. Offer to clean up source branch
```

## History Cleanup Sequence

```
1. Analyze recent commit history
2. Identify cleanup opportunities:
   - squash related commits
   - reword unclear messages
   - reorder for logical flow
3. Present cleanup plan
4. User confirmation
5. Create backup branch
6. Execute interactive rebase
7. Handle any conflicts
8. Verify clean history
```

## Operation Verification Checklist

After every sequence:
- [ ] Expected state achieved
- [ ] No unintended changes
- [ ] Working directory clean (or documented)
- [ ] Recovery options available if needed
