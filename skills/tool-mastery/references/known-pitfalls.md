# Known Pitfalls and Workarounds

## 🔴 P1: LLM Output Word Stripping (GLM-5.1)

**Symptom:** Python `import` statements fail with `SyntaxError: invalid syntax`. Code appears to have missing words. Variables and function names vanish silently.

**Root Cause:** The ZAI GLM-5.1 model strips certain common programming words from its generated output before the text reaches Agent Zero. This is a provider-side content filter, NOT an Agent Zero framework issue.

**Diagnosis:** Write the suspect word to a file from Python (`chr()` construction), then read the file back. If the file contains the word but your tool_args don't, the LLM is stripping it.

**Workarounds:**

1. **Write scripts to file via heredoc, then execute:**
   bash
   cat > /tmp/diag.py << 'SCRIPT'
   import os, importlib
   target = chr(74) + chr(83) + chr(79) + chr(78)
   j = importlib.import_module(target.lower())
   SCRIPT
   python3 /tmp/diag.py
   

2. **Construct words dynamically in Python:**
   python
   target = chr(74) + chr(83) + chr(79) + chr(78)
   mod = __import__(target.lower())
   

3. **Use `importlib.import_module()` instead of `import` statement** — the module name is a variable, not a keyword the LLM generates literally.

**Confirmed NOT caused by:**
- Secrets masking (secrets.env is empty, no secret values match)
- StreamingSecretsFilter (no-op with empty secrets)
- ALIAS_PATTERN regex (doesn't match plain words)
- Any Agent Zero extension (all 30+ scanned)

---

## 🔴 P2: Unbounded Terminal Output (Fixed)

**Symptom:** Session killed, context window exceeded, massive message files in chat logs.

**Root Cause:** `truncate_text_agent` had a hardcoded threshold of 1,000,000 characters (~250K tokens). Commands like `grep -r` on directories with minified JS could produce 1MB output that fit just under the limit.

**Fix Applied:** `max_output_chars` now configurable in `_code_execution/default_config.yaml`, default 30,000 (~7.5K tokens). Committed as `05bc545e`.

**Prevention Rules:**
- ALWAYS pipe: `| head -20`, `| tail -20`, `| wc -l`
- NEVER run `grep -r` without `--include='*.py'` or similar filter
- NEVER `cat` binary or minified files
- For large output: redirect to file, then read portions with `text_editor`

---

## 🟡 P3: Python Import Chain Failures in Diagnostics

**Symptom:** `ModuleNotFoundError: No module named 'webcolors'` or `'litellm'` when trying to import `helpers.secrets`.

**Root Cause:** The venv at `/opt/venv/` doesn't include all framework dependencies when invoked from `code_execution_tool`. Some imports like `helpers.secrets` → `helpers.extension` → `helpers.print_style` → `webcolors` fail.

**Workaround:**
- Don't import the full framework chain in diagnostics
- Read source files directly with `sed`/`grep` instead of importing
- Write standalone scripts that don't depend on framework modules
- If you need framework modules: `pip install webcolors -q` first

---

## 🟡 P4: text_editor Returns 0 Lines for Empty Files

**Symptom:** `text_editor read` returns `0 lines` for a file that exists.

**Root Cause:** The file is genuinely 0 bytes (e.g., empty `secrets.env`).

**Not a bug** — but can be confusing if you expect content. Always check file size first: `ls -la /path/to/file`.

---

## 🟡 P5: keyring Tool Name Confusion

**Symptom:** Trying to call `keyring` as a tool fails.

**Root Cause:** The keyring tool uses method-style naming: `keyring:get`, `keyring:set`, `keyring:list`, `keyring:delete`. The base `keyring` is not a callable tool.

**Correct usage:**

{"tool_name": "keyring:get", "tool_args": {"name": "SECRET_NAME"}}
``n
---

## 🟡 P6: Git Identity Not Configured

**Symptom:** `git commit` fails with `Author identity unknown`.

**Fix:**
bash
git config user.email "jarvis@adrianhomelab.com"
git config user.name "J.A.R.V.I.S."
``n
Or set global identity. Already configured in current repo.

---

## 🟡 P7: credentials in Remote URL

**Symptom:** GitHub PAT visible in `git remote -v` output.

**Root Cause:** During fork setup, remote URL was set as `https://TOKEN@github.com/...`

**Fix:** Set clean URL and configure credential helper:
bash
git remote set-url origin https://github.com/user/repo.git
echo "https://user:TOKEN@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
git config credential.helper store
``n
---

## 🟢 P8: Heredoc Delimiter Choice

**Best Practice:** Always use single-quoted heredoc delimiters:
bash
cat > /tmp/script.py << 'SCRIPT'
# Variables NOT expanded — safe for $var, backticks
SCRIPT
``n
Without single quotes (`<< SCRIPT`), shell expands `$variables` and backticks inside the heredoc, which can corrupt Python code containing `$` signs or shell commands.

---

## 🟢 P9: skill_tool Search Before Load

**Symptom:** Loading a skill by guessed name fails.

**Rule:** ALWAYS `search` before `load`, even when the name seems obvious:

{"tool_name": "skills_tool", "tool_args": {"action": "search", "query": "document query"}}
``nThen load by exact `skill_name` from results.
