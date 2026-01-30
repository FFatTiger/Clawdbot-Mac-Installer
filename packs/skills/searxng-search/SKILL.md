---
name: searxng-search
description: Use when the user asks to web search /查资料/搜一下/搜索网页. Performs searches via the user's SearXNG instance (self-hosted) instead of any built-in search tool.
metadata: {"clawdbot":{"requires":{"bins":["python3"]}}}
---

Use the user’s SearXNG instance for web search.

Default behavior
- Base URL: taken from env `SEARXNG_BASE_URL` when set; otherwise defaults to `http://localhost:8888`
- Endpoint: `GET /search?q=...&format=json`

How to search
Run the bundled script:

python3 {baseDir}/scripts/searxng_search.py "<query>" --count 5 --lang zh-CN --safesearch 0

Notes
- Prefer `--count 5` by default; use 10 only when the user asks for breadth.
- For Chinese queries, default `--lang zh-CN`; for English queries, `--lang en`.
- If the user asks for “safe search”, set `--safesearch 1` (moderate) or `2` (strict).

Output format to the user
- Return bullet points: Title — URL + 1-line snippet.
- If asked to open/read a result, fetch that URL and summarize.

Fallback
If SearXNG is unreachable:
- Say it’s unavailable and suggest configuring `SEARXNG_BASE_URL` or fixing the server.
