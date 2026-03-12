#!/usr/bin/env python3
import argparse, json, pathlib


def body_prompts(topic: str, city: str, theme: str, style: str):
    return [
        {
            "name": "subject-main",
            "prompt": f"请参考已上传图片，生成一张适合小学生艺术节参赛的{style}作品图，主题为{topic}。重点表现儿童主体、{theme}、校园氛围，纯白背景，竖版3:4，主体明确，所有镂空相连，避免细线和碎孔，不要任何文字或水印。"
        },
        {
            "name": "city-symbols",
            "prompt": f"请参考已上传图片，生成一张{style}风格作品图，主题为{city}与{theme}。突出城市地标轮廓、儿童成长氛围、适合小学生艺术节参赛，纯白背景，竖版3:4，可剪纸实现，不要文字或水印。"
        },
        {
            "name": "clean-composition",
            "prompt": f"请参考已上传图片，生成一张构图简洁、主体突出的{style}作品图，主题为{topic}。要求大形块、轮廓清晰、可剪纸实现、儿童友好、纯白背景、竖版3:4，不要任何文字或水印。"
        },
        {
            "name": "festival-posterish",
            "prompt": f"请参考已上传图片，生成一张更有参赛作品感的{style}图，主题为{topic}。画面要有阳光成长与校园艺术节气息，儿童主体清晰，纯白背景，竖版3:4，保持剪纸可实现性，不要任何文字或水印。"
        }
    ]


def cover_prompts(topic: str, city: str, theme: str, style: str):
    return [
        {
            "name": "cover-main",
            "prompt": f"请参考已上传图片，为小红书笔记生成一张高辨识度封面图。主题为{topic}，保留{style}风格和儿童艺术节气质，主体更集中、更适合封面展示，竖版3:4，纯白背景，不要任何文字或水印。"
        },
        {
            "name": "cover-clean",
            "prompt": f"请参考已上传图片，生成一张适合小红书封面的{style}图，主题为{city}、{theme}。要求视觉中心明确、构图高级、缩略图可读性强，竖版3:4，不要文字或水印。"
        }
    ]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["body", "cover"])
    ap.add_argument("--topic", required=True)
    ap.add_argument("--city", default="")
    ap.add_argument("--theme", default="")
    ap.add_argument("--style", default="红色剪纸")
    args = ap.parse_args()

    items = body_prompts(args.topic, args.city or args.topic, args.theme or args.topic, args.style) if args.mode == "body" else cover_prompts(args.topic, args.city or args.topic, args.theme or args.topic, args.style)
    print(json.dumps(items, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
