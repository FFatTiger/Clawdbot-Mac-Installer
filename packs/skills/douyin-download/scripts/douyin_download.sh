#!/usr/bin/env bash
set -euo pipefail

# Download Douyin/TikTok/Bilibili media via Douyin_TikTok_Download_API (/api/download)
# Usage:
#   douyin_download.sh "<share text or url>" [--watermark]
# Env:
#   DOYIN_API_BASE_URL (default: http://localhost:8030)
#   DOYIN_OUTDIR (optional) override output dir

input=${1:-}
if [[ -z "${input}" ]]; then
  echo "ERROR: missing input (share text or url)" >&2
  exit 2
fi

with_watermark=false
if [[ "${2:-}" == "--watermark" ]]; then
  with_watermark=true
fi

base_url="${DOYIN_API_BASE_URL:-http://localhost:8030}"

# Compute workspace root from script location: <workspace>/skills/<skill>/scripts
workspace_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
outdir="${DOYIN_OUTDIR:-$workspace_dir/out/douyin}"
mkdir -p "$outdir"

# Extract first URL from share text
url=$(python3 -c 'import re,sys
s=sys.argv[1]
m=re.search(r"https?://\S+", s)
if not m:
  print("")
else:
  u=m.group(0).rstrip(")】】】,.;!，。；！")
  print(u)
' "$input")

# If it is a b23.tv short link, resolve it to the final bilibili URL (more stable for some servers)
if [[ "$url" == https://b23.tv/* ]]; then
  resolved=$(curl -sS -L -o /dev/null -w '%{url_effective}' "$url" || true)
  if [[ -n "${resolved:-}" ]]; then
    url="$resolved"
  fi
fi

if [[ -z "${url}" ]]; then
  echo "ERROR: no http(s) url found in input" >&2
  exit 3
fi

headers=$(mktemp)
tmpfile=$(mktemp)

# Download (file response). Use --get + --data-urlencode to avoid manual URL encoding.
http_code=$(curl -sS -L \
  -D "$headers" \
  -o "$tmpfile" \
  -w '%{http_code}' \
  --get "$base_url/api/download" \
  --data-urlencode "url=$url" \
  --data "prefix=true" \
  --data "with_watermark=$with_watermark")

if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
  echo "ERROR: API returned HTTP $http_code" >&2
  echo "---- response headers ----" >&2
  cat "$headers" >&2
  rm -f "$headers" "$tmpfile"
  exit 4
fi

# If API returned JSON (error payload), surface it and fail.
if grep -qiE '^content-type:\s*application/json' "$headers"; then
  echo "ERROR: API returned JSON instead of a media file:" >&2
  cat "$tmpfile" >&2
  rm -f "$headers" "$tmpfile"
  exit 5
fi

# Fallback: detect JSON even if content-type is wrong
if [[ "$(head -c 1 "$tmpfile" 2>/dev/null || true)" == "{" ]]; then
  if python3 -c 'import json,sys; json.load(open(sys.argv[1]));' "$tmpfile" >/dev/null 2>&1; then
    echo "ERROR: API returned JSON instead of a media file:" >&2
    cat "$tmpfile" >&2
    rm -f "$headers" "$tmpfile"
    exit 5
  fi
fi

# Determine filename
filename=$(python3 -c 'import re,sys
h=open(sys.argv[1],"r",errors="ignore").read().splitlines()
cd=""; ct=""
for line in h:
  l=line.lower()
  if l.startswith("content-disposition:"):
    cd=line
  if l.startswith("content-type:"):
    ct=line
fn=""
if cd:
  m=re.search(r"filename\*=UTF-8''([^;]+)", cd, re.I)
  if m:
    fn=m.group(1)
  else:
    m=re.search(r"filename=\"?([^\";]+)\"?", cd, re.I)
    if m:
      fn=m.group(1)
if not fn:
  ctype=ct.split(":",1)[1].strip().lower() if ct else ""
  ext="bin"
  if "video/mp4" in ctype: ext="mp4"
  elif "application/zip" in ctype: ext="zip"
  elif "image/jpeg" in ctype: ext="jpg"
  elif "image/png" in ctype: ext="png"
  fn=f"download.{ext}"
fn=re.sub(r"[^A-Za-z0-9._-]+","_",fn)
print(fn)
' "$headers")

# Ensure uniqueness
base="$outdir/$filename"
final="$base"
if [[ -e "$final" ]]; then
  ts=$(date +%Y%m%d-%H%M%S)
  final="$outdir/${filename%.*}-$ts.${filename##*.}"
fi

mv "$tmpfile" "$final"
rm -f "$headers"

echo "$final"
