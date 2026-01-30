---
name: pic-api
description: 聚合多个图片 API 的脚本技能（动漫/随机美图等）。
metadata: {"clawdbot":{"requires":{"bins":["python3"]}}}
---

本技能集成了多个公开图片 API，通过统一脚本调用。

使用方法
python3 {baseDir}/scripts/fetch.py "<类型/关键词>" [--r18]

依赖
- Python 3
- Python 包：requests（安装：python3 -m pip install --user requests）

存储路径
- 图片保存到 `<workspace>/out/pic-api/`（脚本会根据自身路径自动定位 workspace）。
