# Tool Reference — Correct Usage Patterns

## code_execution_tool

### Runtime Selection

| Runtime | When to Use |
|---|---|
| `terminal` | Shell commands, pip installs, git, system operations |
| `python` | Python scripts, data processing, diagnostics |
| `nodejs` | JavaScript execution |
| `output` | Poll running session — never use for new commands |

### Session Management

``nSession 0  → default for all commands
Session 1  → separate session for long-running work
reset=true → kill stuck session before reusing
``n
### Correct Patterns

**Split long work:**
python
# Step 1: inspect
echo 'Checking disk...' && df -h | head -5

# Step 2: prepare
mkdir -p /tmp/work && cd /tmp/work

# Step 3: run (with output redirect for long jobs)
python3 long_script.py > /tmp/work/output.log 2>&1 &

# Step 4: poll
# Use runtime=output, session=0 to check progress
``n
**Python heredoc:**
bash
python3 << 'SCRIPT'
# Single-quoted 'SCRIPT' prevents variable expansion
import os, sys
# ... code ...
SCRIPT
``n
**Diagnostic script to file (bypasses LLM output stripping):**
bash
cat > /tmp/diag.py << 'SCRIPT'
import os
target = chr(74) + chr(83) + chr(79) + chr(78)
# ... diagnostic code ...
SCRIPT
python3 /tmp/diag.py
``n
### Incorrect Patterns

python
# WRONG: unbounded grep on directory with binary files
grep -r "auth" /large/dir/  # Could produce MB of output

# WRONG: blocking on long-running command
python3 train_model.py  # Will timeout

# WRONG: not checking exit code
pip install missing-package  # Silent failure
``n
---

## text_editor

### Actions

| Action | When |
|---|---|
| `read` | Read file with optional line ranges |
| `write` | Create or overwrite entire file |
| `patch` | Edit existing file — minimal surgical changes |

### Correct Patterns

**Read before patch:**
``n1. text_editor read path=/app/main.py line_from=1 line_to=50
2. text_editor patch path=/app/main.py old_text="status='draft'" new_text="status='ready'"
``n
**Patch with context (patch_text):**
``ntext_editor patch path=/app/main.py patch_text="@@ def configure():
-old_setting = True
+new_setting = False
"
``n
### Incorrect Patterns

python
# WRONG: using code_execution_tool for file writes
echo 'content' > file.py  # Use text_editor write

# WRONG: patch without reading first
text_editor patch path=/file.py old_text="..."  # Guess = mismatch

# WRONG: full rewrite for tiny change
text_editor write path=/huge_file.py content="..."  # Use patch
``n
---

## search_engine

### Query Rules

| Bad (natural language) | Good (keywords) |
|---|---|
| "What is the latest Python version?" | `Python 3.13 release notes` |
| "How much does a Tesla Model 3 cost?" | `Tesla Model 3 price 2026` |
| "Find information about Proxmox VE 8" | `Proxmox VE 8 features changelog` |

---

## memory_save / mempalace_save

### Decision Tree

``nIs it durable across sessions?
  NO → don't memorize
  YES → Is it >60 chars or a credential/IP?
    NO → don't memorize
    YES → Does it update an existing memory?
      YES → load old, forget old, save new
      NO → save with type and metadata
``n
### Type Selection

| Type | Example |
|---|---|
| `fact` | "Proxmox host at 192.168.0.102 runs PVE 8.4" |
| `decision` | "Use branch 'homelab' for custom patches" |
| `preference` | "Adrian prefers British English" |
| `credential` | Keyring reference (never inline value) |
| `solution` | "Output truncation fixed by setting max_output_chars=30000" |
| `milestone` | "Fork created at github.com/user/agent-zero" |

---

## call_subordinate

### Profile Matching

| Task Type | Profile |
|---|---|
| Research, data analysis | `researcher` |
| Code development | `developer` |
| Security, pentesting | `hacker` |
| HA automation | `ha-automator` |
| Email, calendar, tasks | `personal-assistant` |
| Quick prototyping | `bmad-quick-dev` |

### Message Template

``nRole: [specialist title]
Goal: [specific deliverable]
Task: [concrete steps]
Constraints: [scope boundaries]
Output: [expected format]
``n
---

## skills_tool

### Workflow

``n1. search → find candidate skills by keyword
2. load → load skill instructions into context
3. read_file → read reference files within skill
4. Follow loaded instructions with other tools
``n
### Trigger Phrases That Require Skill Search

- Document reading, OCR → search `document query`
- Browser automation → search `browser automation`
- Host file editing → search `host file editing`
- Scheduled tasks → search `scheduled tasks`
- Home Assistant → search `home assistant`

---

## response

### When to Use

- Final answer to user
- Task complete
- No active task
- Asking a blocking question

### When NOT to Use

- Mid-task progress updates → use `notify_user`
- Still investigating → continue with tools
- Partial results → keep going

---

## notify_user

### Types

| Type | When |
|---|---|
| `info` | Neutral notification, normal priority (10) |
| `success` | Task completed successfully |
| `warning` | Potential issue, proceed with caution |
| `error` | Failure requiring attention |
| `progress` | Long-running task update |

---

## scheduler

### Task Types

| Type | When |
|---|---|
| `create_scheduled_task` | Recurring cron jobs |
| `create_planned_task` | One-time future execution |
| `create_adhoc_task` | Immediate or manual trigger |

### Cron Format

``n{"minute": "0", "hour": "9", "day": "*", "month": "*", "weekday": "*"}
``nAlways include `timezone` for user-named timezones.
