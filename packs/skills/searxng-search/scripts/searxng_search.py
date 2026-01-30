#!/usr/bin/env python3
import argparse
import json
import sys
import textwrap
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

def fetch_json(url: str, timeout: float = 15.0):
    req = Request(url, headers={"User-Agent": "clawdbot-searxng-skill/1.0"})
    with urlopen(req, timeout=timeout) as resp:
        data = resp.read()
    return json.loads(data.decode("utf-8", errors="replace"))

def main():
    ap = argparse.ArgumentParser(description="Search via SearXNG and print concise results")
    ap.add_argument("query", help="search query")
    import os
    ap.add_argument("--base", default=os.environ.get("SEARXNG_BASE_URL", "http://localhost:8888"), help="SearXNG base URL")
    ap.add_argument("--count", type=int, default=5, help="max results to print")
    ap.add_argument("--lang", default="zh-CN", help="language code")
    ap.add_argument("--safesearch", type=int, default=0, choices=[0,1,2], help="0 off, 1 moderate, 2 strict")
    ap.add_argument("--timeout", type=float, default=15.0, help="HTTP timeout seconds")
    args = ap.parse_args()

    params = {
        "q": args.query,
        "format": "json",
        "language": args.lang,
        "safesearch": str(args.safesearch),
    }
    url = args.base.rstrip("/") + "/search?" + urlencode(params)

    try:
        payload = fetch_json(url, timeout=args.timeout)
    except HTTPError as e:
        sys.stderr.write(f"HTTPError: {e.code} {e.reason}\n")
        sys.exit(2)
    except URLError as e:
        sys.stderr.write(f"URLError: {e}\n")
        sys.exit(3)
    except Exception as e:
        sys.stderr.write(f"Error: {e}\n")
        sys.exit(1)

    results = payload.get("results") or []
    out = []
    for r in results[: max(0, args.count)]:
        title = (r.get("title") or "").strip() or "(no title)"
        href = (r.get("url") or "").strip()
        content = (r.get("content") or "").strip()
        snippet = " ".join(content.split())
        if len(snippet) > 220:
            snippet = snippet[:217] + "..."
        out.append({"title": title, "url": href, "snippet": snippet})

    sys.stdout.write(json.dumps({"query": args.query, "results": out}, ensure_ascii=False, indent=2) + "\n")

if __name__ == "__main__":
    main()
