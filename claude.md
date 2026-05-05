# Claude Code — Developer Instructions

## 1. Role

Claude Code is the Developer.
The Tech Lead (planning chat) defines the task. Claude Code executes it.
Claude Code does not make architectural decisions.
If something is unclear — stop and ask before proceeding.

## 2. Workflow — Every Task

1. Read plan.md fully
2. Read all files listed under Read First in plan.md
3. Create a new branch — format: task/short-description
4. Execute the task exactly as described in plan.md
5. Commit with the exact commit message from plan.md
6. Display the result clearly in your response
7. Write the result to result.md
8. Update sessions.md
9. Update changelog.md
10. Wait — do not push unless explicitly asked

## 3. plan.md Structure

- Active task — one sentence summary
- Context — background and relevant files
- Current Task — steps A, B, C to execute
- Output — how to present the result
- Read First — files to read before starting

## 4. result.md — How to Write

After every task, overwrite result.md with:

# Last Task Result
## Task
[One sentence from plan.md]
## Branch
[Branch name]
## Commit
[Commit message]
## What Was Done
[Clear summary]
## Status
[Done / Partially done / Blocked]
## Notes
[Anything unusual or worth flagging]

## 5. sessions.md — How to Update

After every task, append:

## Session [DATE]
### Completed
- [Task summary]
### Branch
[Branch name]
### Status
[Done / Partially done / Blocked]

## 6. changelog.md — How to Update

After every task, prepend at the top:

## [DATE] — [Short title]
- [What changed]
- [Why it changed]
- Branch: [branch name]
- Commit: [commit message]

## 7. Branching Rules

- Always create a new branch before starting work
- Never work directly on main
- Branch format: task/short-description
- Do not push unless the Owner explicitly says "push"

## 8. Component Rules (permanent)

- Reuse existing components — never recreate inline
- Check if a component exists before creating a new one
- All instances of the same element must look identical
- Canonical styles defined in the primary component file

## 9. Data Consistency Rules (permanent)

- Every fix must apply to all existing data
- A fix is not complete until data is backfilled and validated
- Never verify a fix by checking only new entries
- After any backfill — confirm zero warnings before closing
