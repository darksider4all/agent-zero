# Code Execution Patterns

## Session Management

### Default Session (0)
Use for all standard commands. Reused across calls.

### Separate Session (1+)
Use for long-running work that shouldn't block the default session.

### Stuck Session
If a session hangs (command won't return), reset it:

{"runtime": "terminal", "session": 0, "reset": true, "code": "echo 'session reset'"}


### Polling Running Work
After starting a background process, poll with:

{"runtime": "output", "session": 0}

Never send new commands while polling. Wait for output to complete.

---

## Heredoc Patterns

### Single-Quoted Delimiter (Recommended)
bash
cat > /tmp/script.py << 'SCRIPT'
import os
# $variables and backticks NOT expanded
# Safe for Python, shell, any code
SCRIPT


### When to Use Which Delimiter

| Delimiter | Expansion | Use Case |
|---|---|---|
| `<< 'SCRIPT'` | None (literal) | Python scripts, code generation |
| `<< SCRIPT` | Yes (shell expands) | Shell templates needing variable substitution |
| `<< 'EOF'` | None (literal) | Alternative to SCRIPT |
| `<< 'PYEOF'` | None (literal) | Python-specific blocks |

### Nested Heredocs (Avoid)
If you need heredocs inside heredocs, write the outer script to a file first, then execute it. Nested heredocs cause delimiter conflicts.

---

## Output Redirection Strategies

### Long-Running Jobs
bash
# Redirect to log file
python3 /tmp/long_job.py > /tmp/job.log 2>&1 &
echo "PID: $!"

# Later: check progress
tail -20 /tmp/job.log


### Capturing Exit Codes
bash
command_that_might_fail
EXIT_CODE=$?
echo "Exit code: $EXIT_CODE"
if [ $EXIT_CODE -ne 0 ]; then
    echo "FAILED"
fi


### Output Size Estimation
Before running potentially large commands:
bash
# Estimate grep output
grep -r "pattern" /dir/ --include='*.py' | wc -l

# If >1000 lines, pipe through head
grep -r "pattern" /dir/ --include='*.py' | head -50


---

## Diagnostic Script Pattern

When debugging framework issues, write diagnostic scripts to /tmp/ files:

### Step 1: Write diagnostic script
bash
cat > /tmp/diag.py << 'SCRIPT'
import os, sys

# Construct words that may be stripped by LLM
target = chr(74) + chr(83) + chr(79) + chr(78)

# Read files directly without framework imports
with open('/path/to/config') as f:
    content = f.read()

# Output results
echo(f"Found {len(content)} bytes")
SCRIPT


### Step 2: Execute
bash
python3 /tmp/diag.py


### Step 3: Clean up
bash
rm /tmp/diag.py


---

## Python Execution Modes

### Inline (Short Scripts)
For 1-5 line scripts:

{"runtime": "python", "code": "import os; print(os.getcwd())"}


### Heredoc (Medium Scripts)
For 5-50 line scripts:

{"runtime": "terminal", "code": "python3 << 'SCRIPT'\nimport os\nprint(os.getcwd())\nSCRIPT"}


### File-Based (Long/Diagnostic Scripts)
For 50+ lines or scripts requiring framework-sensitive words:

{"runtime": "terminal", "code": "cat > /tmp/script.py << 'SCRIPT'\n...\nSCRIPT\npython3 /tmp/script.py"}


---

## Dependency Management

### Check Before Install
bash
# Check if package exists
python3 -c "import package_name" 2>/dev/null && echo "installed" || echo "missing"

# Install quietly
pip install package_name -q


### Venv Path
The active venv is at `/opt/venv/`. Python binary: `/opt/venv/bin/python3`.

---

## Git Patterns

### Safe Commit Workflow
bash
# Check status first
git status

# Stage specific files (not all)
git add specific_file.py

# Verify what's staged
git diff --cached --stat

# Commit with descriptive message
git commit -m "fix: description of change"

# Push
git push origin branch_name


### Branch Operations
bash
# Create and switch
git checkout -b new-branch

# Rebase onto upstream
git fetch upstream
git rebase upstream/main

# Force push after rebase
git push origin branch_name --force


---

## Common Diagnostic Commands

### Find Large Files
bash
find /a0 -type f -size +1M -exec ls -lh {} \; | sort -k5 -h | tail -20


### Check Running Processes
bash
ps aux | grep -E 'python|node' | grep -v grep


### Disk Usage
bash
df -h | head -10
du -sh /a0/usr/chats/*/messages/ | sort -h | tail -10


### Network Connectivity
bash
curl -s -o /dev/null -w "%{http_code}" http://192.168.0.112:19999
