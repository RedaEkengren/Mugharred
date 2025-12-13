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