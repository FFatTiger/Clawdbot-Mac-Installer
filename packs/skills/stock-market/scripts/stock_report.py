#!/usr/bin/env python3
import sys
import json
import urllib.request
from datetime import datetime

def fetch_json(url):
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        return {"error": str(e)}

def format_stock_data():
    # 上证指数 API (东方财富)
    index_url = "http://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=1&po=1&np=1&ut=bd1d9ddb04089700cf9c27f6f7426281&fltt=2&invt=2&fid=f3&fs=i:1.000001&fields=f1,f2,f3,f4,f5,f6,f7,f12,f13,f14"
    # 行业板块 API (东方财富)
    sector_url = "http://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=10&po=1&np=1&ut=bd1d9ddb04089700cf9c27f6f7426281&fltt=2&invt=2&fid=f3&fs=m:90+t:2&fields=f1,f2,f3,f4,f12,f14"

    index_data = fetch_json(index_url)
    sector_data = fetch_json(sector_url)

    result = []
    
    # 解析大盘
    if "data" in index_data and "diff" in index_data["data"]:
        idx = index_data["data"]["diff"][0]
        result.append(f"【上证指数行情】")
        result.append(f"名称: {idx['f14']} ({idx['f12']})")
        result.append(f"收盘: {idx['f2']:.2f}")
        result.append(f"涨跌: {idx['f4']:.2f} ({idx['f3']:.2f}%)")
        result.append(f"成交量: {idx['f5']/1000000:.2f}M / 成交额: {idx['f6']/100000000:.2f}亿")
        result.append("")

    # 解析板块
    if "data" in sector_data and "diff" in sector_data["data"]:
        result.append(f"【热门板块涨跌幅 (Top 10)】")
        for s in sector_data["data"]["diff"]:
            change_percent = s['f3']
            prefix = "+" if change_percent > 0 else ""
            result.append(f"- {s['f14']}: {prefix}{change_percent:.2f}%")

    if not result:
        return "未能获取到有效的市场数据，请检查网络或数据源。"

    return "\n".join(result)

if __name__ == "__main__":
    print(format_stock_data())
