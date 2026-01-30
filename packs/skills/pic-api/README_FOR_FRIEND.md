pic-api 技能使用说明书

这是一个集成了多个动漫/美图 API 的 Clawdbot 技能。

1) 安装方法
- 将 pic-api 文件夹放置在你的 Clawdbot workspace 的 skills 目录下（通常是 ~/clawd/skills/）。
- 确保安装 requests：
  python3 -m pip install --user requests

2) 功能特性
- 动漫/色图模式：输入包含“色图”“二次元”“r18”等关键词时，可触发 R18。
- 本地存储：下载图片保存在 <workspace>/out/pic-api/（脚本会自动定位 workspace）。

3) 使用方法
- 对话：来张二次元图 / 来张 r18
- 手动执行：python3 skills/pic-api/scripts/fetch.py "二次元" --r18

4) 核心文件
- SKILL.md
- scripts/fetch.py
