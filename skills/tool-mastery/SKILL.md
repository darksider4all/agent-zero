---
name: tool-mastery
description: Correct usage patterns for all Agent Zero tools. Load when diagnosing tool issues, reviewing tool call hygiene, onboarding new workflows, or debugging unexpected tool behaviour. Covers code execution, file editing, memory, search, subordinates, browser, and known pitfalls including LLM output word stripping.
---

# Tool Mastery

Correct usage patterns for all Agent Zero tools. Load this skill when diagnosing tool issues, onboarding new workflows, or reviewing tool call hygiene.

## Tool Selection Priority

``n1. Question/answer → response (no tool needed)
2. File read/edit → text_editor (not code_execution cat/sed)
3. Web research → search_engine (not browser for simple queries)
4. Document Q&A/OCR → document_query (load skill first)
5. Shell command → code_execution_tool terminal
6. Python script → code_execution_tool python
7. Complex research → call_subordinate (researcher profile)
8. Skill-gated tool → load skill first, then call tool
``n
## Critical Rules

### Code Execution
- ALWAYS pipe large outputs: `| head`, `| tail`, `| wc`, `| grep`
- Split long work into: inspect → prepare → run → verify
- Poll running work with `runtime=output`, never block
- For Python: prefer `<< 'SCRIPT'` heredoc over multi-line `-c`
- Write diagnostic scripts to `/tmp/` files, then execute — avoids LLM output stripping
- After timeout: inspect logs/processes before retrying

### File Operations
- `text_editor` for read/write/patch — NOT `code_execution_tool cat/echo`
- Read before patching — use exact `old_text` matches
- For files >500 lines: use `line_from`/`line_to` or `document_query`
- `office_artifact` for ODT/ODS/ODP/DOCX/XLSX — NOT `text_editor`

### Memory
- `mempalace_save` over raw `memory_save` — typed memories with metadata
- NEVER memorize: filler, status updates, <60 char strings, partial outputs
- Only memorize: infrastructure facts, solved problems, preferences, credentials, scheduled items
- Update stale memories: load → forget old → save new (never append duplicates)

### Subordinates
- Match profile to task: researcher for research, developer for code, hacker for security
- Never delegate full task to same-profile subordinate
- Include clear role, goal, and concrete deliverable in message
- Set `reset: true` for first message or profile change

### Browser
- Use `search_engine` for simple web queries — browser is for interaction
- `content` returns refs — use refs for clicks, not coordinates
- Close tabs after extracting data
- NEVER use `browser_agent` — use `search_engine` and `document_query`

### Search
- Keywords only, not natural language questions
- 3-10 high-signal terms with exact phrases and model numbers
- BAD: "What is the latest LiteLLM release?"
- GOOD: "LiteLLM latest release notes changelog"

## Known LLM Output Limitations

The GLM-5.1 model strips certain common programming words from output. When code fails with unexpected syntax errors, check for missing keywords. Workaround: construct words dynamically with `chr()` codes or write scripts to file using heredoc with `'SCRIPT'` delimiter (single-quoted prevents variable expansion).

## Output Safety

Terminal output is truncated at 30,000 characters (configurable in `_code_execution/default_config.yaml`). Never rely on getting full output from unbounded commands. Always estimate output size before running.

## When to Load Additional Skills

- `document-query` before `document_query` tool
- `browser-automation` before complex browser workflows
- `host-code-execution` before `code_execution_remote`
- `scheduled-tasks` before complex scheduler work
- `home-assistant-manager` before HA MCP tools

## Detailed References

Load with `skills_tool action=read_file`:
- `references/tool-reference.md` — Per-tool correct/incorrect patterns
- `references/known-pitfalls.md` — All discovered gotchas and workarounds
- `references/code-execution-patterns.md` — Sessions, heredocs, diagnostics
