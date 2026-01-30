import sys
import os
import requests
import time
import re

# 配置：根据脚本位置自动定位 workspace
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
WORKSPACE_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "../../.."))
OUT_DIR = os.path.join(WORKSPACE_DIR, "out", "pic-api")
os.makedirs(OUT_DIR, exist_ok=True)

def fetch_lolicon(r18=False):
    url = f"https://api.lolicon.app/setu/v2?r18={1 if r18 else 0}"
    try:
        resp = requests.get(url, timeout=10).json()
        if not resp.get("data"):
            return None, "API 返回数据为空"
        img_data = resp["data"][0]
        img_url = img_data["urls"]["original"]
        ext = img_data.get("ext", "png")
        filename = f"lolicon_{int(time.time())}.{ext}"
        return img_url, filename
    except Exception as e:
        return None, str(e)

def download_file(url, filename):
    path = os.path.join(OUT_DIR, filename)
    try:
        r = requests.get(url, stream=True, timeout=30)
        r.raise_for_status()
        with open(path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        return path
    except Exception as e:
        return f"下载失败: {str(e)}"

def main():
    if len(sys.argv) < 2:
        print("错误: 缺少关键词参数")
        return

    query = sys.argv[1].lower()
    r18 = "--r18" in sys.argv or "色图" in query or "r18" in query

    # 目前逻辑：只要包含二次元或色图，就走 lolicon
    if "二次元" in query or "色图" in query or "anime" in query:
        print(f"正在匹配 Lolicon API (R18: {r18})...")
        url, info = fetch_lolicon(r18)
    else:
        # 默认回退到 lolicon 的普通图
        url, info = fetch_lolicon(r18=False)

    if not url:
        print(f"未能获取到图片链接: {info}")
        return

    print(f"获取链接成功: {url}")
    result_path = download_file(url, info)
    print(result_path)

if __name__ == "__main__":
    main()
