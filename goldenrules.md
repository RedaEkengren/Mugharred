# GOLDEN RULES — READ FIRST

This repository is **STRICTLY SCRIPT-DRIVEN**.

If you are an AI, agent, assistant, or human:
You MUST follow these rules.
They are NON-NEGOTIABLE.

---

## CORE PRINCIPLES

- There is ONE source of truth.
- There is ONE valid structure.
- There is ONE way to change state: **SCRIPTS**.

Anything else leads to corruption.

---

## ABSOLUTE PROHIBITIONS

The following are FORBIDDEN:

- Creating files manually
- Creating test files or temporary files
- Creating duplicate folders
- Creating alternative builds or dist directories
- Copying files outside of approved scripts
- "Trying", "testing", or "experimenting" in the file system
- Modifying production paths manually
- Guessing which folder is correct

If any of these occur: **STOP IMMEDIATELY**.

---

## ALLOWED OPERATIONS

The ONLY allowed operations are:

### 1. READ-ONLY INSPECTION
- `ls`
- `find`
- `cat`
- `grep`

No writes. No side effects.

### 2. SCRIPTED CHANGES
All changes MUST happen via:
- bash scripts
- npm scripts
- explicit `rm` / `mv` commands AFTER approval

If an operation is not scripted, it MUST NOT happen.

---

## MANDATORY WORKFLOW

All work MUST follow this order:

1. INVENTORY  
   Read-only inspection only.

2. PLAN  
   Text-only explanation of:
   - canonical structure
   - what is valid
   - what is invalid
   - WHY

3. EXECUTE  
   Minimal, explicit scripts or commands.
   No extras. No variations.

Skipping a step is forbidden.

---

## CANONICAL PROJECT STRUCTURE

This repository recognizes ONLY the following structure:

/frontend → client application (builds to frontend/dist)
/backend → server application (builds to backend/dist)
/scripts → all state-changing scripts
/golden.md → this file


Any other project, dist, build, or nested structure is INVALID unless explicitly approved.

---

## DIST / BUILD RULES

- Frontend build output: `frontend/dist`
- Backend build output: `backend/dist`
- Root `dist/` is FORBIDDEN
- Root builds are FORBIDDEN

If a root `dist/` exists, it is INVALID by definition.

---

## DEPLOYMENT RULES

- Deployment MUST come from ONE known path only
- Deployment MUST be performed via script
- `index.html` and its referenced assets MUST originate from the SAME build

Deploying mixed or mismatched assets is considered corruption.

---

## AI-SPECIFIC RULES

If you are an AI agent:

- You may NOT create files freely
- You may NOT duplicate directories
- You may NOT generate alternative solutions in parallel
- You may NOT "try something and see"

You MUST:
- ask for inventory first
- wait for approval before execution
- stop if rules are unclear

Failure to comply = TERMINATE TASK.

---

## SAFETY GUARANTEE

These rules exist to:
- prevent chaos
- prevent silent corruption
- prevent broken deployments
- preserve operator sanity

They override all convenience.

---

## FINAL CLAUSE

If any instruction conflicts with this file:

**THIS FILE WINS.**

No exceptions.