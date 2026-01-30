---
name: douyin-download
description: Download Douyin/TikTok/Bilibili videos/images via a user-provided Douyin_TikTok_Download_API instance, return no-watermark media, and send the file back.
metadata: {"clawdbot":{"requires":{"bins":["curl","python3"]}}}
---

Use this skill when the user sends a Douyin/TikTok/Bilibili share link (or share-text containing a link) and asks you to fetch the no-watermark video (or image set) and send it back.

Environment
- Requires a running Douyin_TikTok_Download_API service.
- Set `DOYIN_API_BASE_URL` to your service base URL (example: http://localhost:8030)

Workflow
1) Extract the first http(s) URL from the user’s message.
2) Download the media via the bundled script:
   {baseDir}/scripts/douyin_download.sh "<share text or url>"
   It saves the file into `<workspace>/out/douyin/` and prints the final path.
3) Send the downloaded file back to the user.

Notes
- If the downloader returns JSON, treat it as an error and report the message.
- Large videos can exceed platform limits; if sending fails, offer an alternative (split/zip, or provide a download link).
