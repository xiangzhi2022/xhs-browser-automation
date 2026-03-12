#!/usr/bin/env python3
import json, sys, pathlib, datetime

topic = sys.argv[1] if len(sys.argv) > 1 else "manual-topic"
out = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else pathlib.Path("payload.json")

payload = {
    "topic": topic,
    "title": f"{topic} 主题内容草稿",
    "content": f"自动化流程为 {topic} 生成的发布草稿。",
    "tags": [topic, "小红书", "自动化"],
    "images": [],
    "createdAt": datetime.datetime.now().isoformat()
}

out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
print(out)
