#!/usr/bin/env python3
import subprocess
import os
import sys

# 路径设置：根据脚本位置自动定位 workspace
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
WORKSPACE_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "../../.."))
DATA_SCRIPT = os.path.join(WORKSPACE_DIR, "skills/stock-market/scripts/stock_report.py")

# 收件人通过环境变量提供（避免把个人信息写进仓库）
RECIPIENT = os.environ.get("STOCK_REPORT_IMESSAGE_TO", "")

def get_stock_report():
    try:
        result = subprocess.run(["python3", DATA_SCRIPT], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except Exception as e:
        return f"获取股市数据失败: {str(e)}"

def send_imessage(content):
    # iMessage 平台不支持 Markdown，必须发送纯文本
    if not RECIPIENT:
        print("缺少收件人：请设置环境变量 STOCK_REPORT_IMESSAGE_TO（例如你的 iMessage 邮箱/手机号）")
        return False

    try:
        subprocess.run(["imsg", "send", "--to", RECIPIENT, "--text", content], check=True)
        return True
    except Exception as e:
        print(f"发送 iMessage 失败: {str(e)}")
        return False

if __name__ == "__main__":
    report = get_stock_report()
    if report:
        # 添加报表时间戳
        import datetime
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        full_message = f"【每日收盘报表】{now}\n\n{report}"
        send_imessage(full_message)
