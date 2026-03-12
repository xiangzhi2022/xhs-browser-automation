#!/usr/bin/env python3
import argparse, json, pathlib, re, subprocess, urllib.parse
from datetime import datetime

COMMONS_API = "https://commons.wikimedia.org/w/api.php"


def fetch_json(url: str):
    out = subprocess.check_output([
        "curl", "-fsSL", "-A", "xhs-browser-automation/0.1", url
    ], text=True)
    return json.loads(out)


def search_commons_images(query: str, limit: int = 5):
    params = {
        "action": "query",
        "generator": "search",
        "gsrsearch": query,
        "gsrnamespace": 6,
        "gsrlimit": limit,
        "prop": "imageinfo|info",
        "iiprop": "url",
        "inprop": "url",
        "format": "json"
    }
    url = COMMONS_API + "?" + urllib.parse.urlencode(params)
    data = fetch_json(url)
    pages = data.get("query", {}).get("pages", {})
    out = []
    for p in pages.values():
        ii = (p.get("imageinfo") or [{}])[0]
        image_url = ii.get("url")
        if not image_url:
            continue
        out.append({
            "title": p.get("title", ""),
            "source": p.get("fullurl", ""),
            "image_url": image_url
        })
    return out


def download(url: str, path: pathlib.Path):
    subprocess.check_call(["curl", "-fsSL", "-A", "xhs-browser-automation/0.1", url, "-o", str(path)])


def safe_name(name: str) -> str:
    return re.sub(r"[^\w\-.]+", "_", name)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--topic", required=True)
    ap.add_argument("--keywords", required=True, help="comma-separated")
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--per-keyword", type=int, default=2)
    args = ap.parse_args()

    out_dir = pathlib.Path(args.out_dir)
    refs_dir = out_dir / "refs"
    refs_dir.mkdir(parents=True, exist_ok=True)

    keywords = [k.strip() for k in args.keywords.split(",") if k.strip()]
    refs = []
    idx = 1
    for kw in keywords:
        queries = [f'{args.topic} {kw}', kw]
        results = []
        for q in queries:
            try:
                results = search_commons_images(q, limit=args.per_keyword)
            except Exception:
                results = []
            if results:
                break
        for r in results:
            ext = pathlib.Path(urllib.parse.urlparse(r['image_url']).path).suffix or '.jpg'
            local = refs_dir / f"ref-{idx:02d}-{safe_name(kw)}{ext}"
            try:
                download(r['image_url'], local)
                refs.append({
                    "keyword": kw,
                    "title": r['title'],
                    "source": r['source'],
                    "image_url": r['image_url'],
                    "local_file": str(local)
                })
                idx += 1
            except Exception as e:
                refs.append({
                    "keyword": kw,
                    "title": r.get('title', ''),
                    "source": r.get('source', ''),
                    "image_url": r.get('image_url', ''),
                    "error": str(e)
                })

    topic = {
        "topic": args.topic,
        "keywords": keywords,
        "createdAt": datetime.now().isoformat(),
        "notes": "Reference collection for Gemini image generation"
    }
    (out_dir / 'topic.json').write_text(json.dumps(topic, ensure_ascii=False, indent=2), encoding='utf-8')
    (out_dir / 'refs.json').write_text(json.dumps({"topic": args.topic, "refs": refs}, ensure_ascii=False, indent=2), encoding='utf-8')
    print(out_dir)
    print(json.dumps({"downloaded": len([r for r in refs if 'local_file' in r]), "total": len(refs)}, ensure_ascii=False))

if __name__ == '__main__':
    main()
