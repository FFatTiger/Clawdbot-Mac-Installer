---
name: stock-market
description: 获取上证指数收盘情况及热门板块涨跌幅数据（东方财富 API）。
metadata: {"clawdbot":{"requires":{"bins":["python3"]}}}
---

获取 A 股市场大盘指数和板块涨跌的实时/收盘数据。

使用方法
- 生成报告：
  python3 {baseDir}/scripts/stock_report.py

可选：发送到 iMessage
- 需要安装并配置 imsg（macOS）
- 设置环境变量 STOCK_REPORT_IMESSAGE_TO
- 运行：
  python3 {baseDir}/scripts/send_daily_report.py

注意
- 数据仅供参考，不构成投资建议。
