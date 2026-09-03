# Git/GitHub

## Task 1 — `git commit -a -m` vs `git commit -m`

| | `git commit -m "msg"` | `git commit -a -m "msg"` |
|---|---|---|
| What it commits | Only what is already **staged** (`git add`) | Auto-**stages** every tracked file that was modified/deleted, then commits |
| New (untracked) files | Never included either way | Still **not** included — `-a` only affects already-tracked files |
| Typical use | When you want to review/curate exactly what goes in via `git add` first | Quick commit of "everything I changed" without a separate `git add` step |

Real proof, see [`task1-commit-a-m-transcript.txt`](task1-commit-a-m-transcript.txt):

1. Modified a tracked file, then ran `git commit -m "..."` **without** `git add` first →
   Git refused: *"no changes added to commit (use "git add" and/or "git commit -a")"*.
2. Ran `git commit -a -m "..."` on the same dirty file → committed immediately, no
   separate `git add` needed.
3. Extra check: created a brand-new untracked file and ran `git commit -a -m` again →
   Git still reported *"nothing added to commit but untracked files present"*, proving
   `-a` only auto-stages **tracked** modifications, never new files.

## Task 2 — Git Cherry-Pick

Real proof, see [`task2-cherry-pick-transcript.txt`](task2-cherry-pick-transcript.txt):

1. Made 3 commits on `main` (feature A, B, C).
2. Created `feature-branch` off `main`.
3. Made 3 commits on the branch: an unrelated cosmetic change, a "critical bugfix",
   and another unrelated feature — each touching its own file so they're independent.
4. Used `git log --oneline` to find the bugfix commit's hash.
5. Switched back to `main` and ran `git cherry-pick <bugfix-hash>`.
6. **Verified**: `bugfix.txt` is now on `main` (and the fix commit shows in
   `git log --oneline`), while `cosmetic.txt` and `wip_feature.txt` — the other two
   branch-only commits — are correctly **absent** from `main`.

**Note on a first attempt:** the first version of this demo had all three branch
commits edit the *same* file, so cherry-picking the middle commit alone produced a
real merge conflict (git needs the commit's parent context to apply a content diff
cleanly) — that's expected, correct git behavior, not a bug. It was rebuilt so each
branch commit touches an independent file, which is the realistic "pull just this one
bugfix" scenario the task is asking about.

Screenshots: [`../screenshots/04-git-task1.png`](../screenshots/04-git-task1.png),
[`../screenshots/04-git-task2.png`](../screenshots/04-git-task2.png)
