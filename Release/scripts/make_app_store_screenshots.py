#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "Release" / "assets"
BG_ROOT = ASSET_ROOT / "source-backgrounds"
OUT_ROOT = ASSET_ROOT / "app-store-screenshots"
SIZE = (2880, 1800)


FONT_CANDIDATES = [
    Path("/Library/Fonts/NotoSansKR-Regular.otf"),
    Path("/Library/Fonts/NotoSansKR-Bold.otf"),
    Path("/System/Library/Fonts/AppleSDGothicNeo.ttc"),
    Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
    Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
]


def font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default(size=size)


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGB")
    src_w, src_h = image.size
    dst_w, dst_h = size
    scale = max(dst_w / src_w, dst_h / src_h)
    resized = image.resize((round(src_w * scale), round(src_h * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - dst_w) // 2
    top = (resized.height - dst_h) // 2
    return resized.crop((left, top, left + dst_w, top + dst_h))


def rounded_rect_layer(
    size: tuple[int, int],
    rect: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] | None = None,
    width: int = 1,
) -> Image.Image:
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(rect, radius=radius, fill=fill, outline=outline, width=width)
    return layer


def add_shadow(
    base: Image.Image,
    rect: tuple[int, int, int, int],
    radius: int,
    blur: int = 36,
    offset: tuple[int, int] = (0, 24),
    alpha: int = 92,
) -> None:
    x1, y1, x2, y2 = rect
    shadow = rounded_rect_layer(
        base.size,
        (x1 + offset[0], y1 + offset[1], x2 + offset[0], y2 + offset[1]),
        radius,
        (0, 0, 0, alpha),
    ).filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(shadow)


def draw_gradient(base: Image.Image, top_alpha: int = 120, bottom_alpha: int = 80) -> None:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    pixels = overlay.load()
    width, height = base.size
    for y in range(height):
        t = y / max(1, height - 1)
        alpha = round(top_alpha * (1 - t) + bottom_alpha * t)
        for x in range(width):
            edge = min(x, width - 1 - x) / (width / 2)
            vignette = round((1 - min(1, edge)) * 72)
            pixels[x, y] = (5, 8, 12, min(210, alpha + vignette))
    base.alpha_composite(overlay)


def pill(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fill: tuple[int, int, int, int]) -> None:
    fnt = font(28)
    pad_x = 24
    pad_y = 12
    w, h = text_size(draw, text, fnt)
    x, y = xy
    draw.rounded_rectangle((x, y, x + w + pad_x * 2, y + h + pad_y * 2), radius=24, fill=fill)
    draw.text((x + pad_x, y + pad_y - 2), text, font=fnt, fill=(245, 250, 252, 255))


def draw_toolbar(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], title: str) -> None:
    x1, y1, x2, _ = rect
    for i, color in enumerate([(255, 95, 87), (255, 189, 46), (40, 201, 64)]):
        draw.ellipse((x1 + 34 + i * 34, y1 + 30, x1 + 54 + i * 34, y1 + 50), fill=color + (255,))
    draw.text((x1 + 148, y1 + 22), title, font=font(30), fill=(226, 235, 240, 255))
    draw.line((x1, y1 + 78, x2, y1 + 78), fill=(255, 255, 255, 30), width=1)


def draw_sidebar(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], active: str = "실시간 번역") -> None:
    x1, y1, x2, y2 = rect
    draw.rounded_rectangle((x1, y1, x2, y2), radius=0, fill=(18, 25, 31, 230))
    draw.text((x1 + 34, y1 + 36), "AirTranslate", font=font(42), fill=(245, 249, 250, 255))
    draw.text((x1 + 34, y1 + 92), "Mac 오디오 자막", font=font(25), fill=(155, 177, 185, 255))
    items = [
        "실시간 번역",
        "플로팅 자막",
        "저장된 기록",
        "설정",
    ]
    y = y1 + 170
    for item in items:
        selected = item == active
        fill = (46, 136, 124, 210) if selected else (255, 255, 255, 0)
        draw.rounded_rectangle((x1 + 24, y, x2 - 24, y + 62), radius=18, fill=fill)
        draw.text((x1 + 52, y + 15), item, font=font(28), fill=(245, 250, 250, 255) if selected else (180, 197, 202, 255))
        y += 78
    y = y2 - 238
    for label, value in [("원문", "English"), ("번역", "한국어"), ("모델", "Apple Speech + Translation")]:
        draw.text((x1 + 34, y), label, font=font(22), fill=(127, 151, 158, 255))
        draw.text((x1 + 34, y + 30), value, font=font(26), fill=(224, 236, 238, 255))
        y += 74


def draw_app_window(base: Image.Image, rect: tuple[int, int, int, int], active: str = "실시간 번역") -> ImageDraw.ImageDraw:
    add_shadow(base, rect, 34)
    base.alpha_composite(rounded_rect_layer(base.size, rect, 34, (15, 20, 25, 238), (255, 255, 255, 42), 2))
    draw = ImageDraw.Draw(base)
    draw_toolbar(draw, rect, "AirTranslate")
    x1, y1, x2, y2 = rect
    sidebar_w = 400
    draw_sidebar(draw, (x1, y1 + 79, x1 + sidebar_w, y2), active=active)
    return draw


def draw_card(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], fill=(245, 249, 250, 238), radius=30) -> None:
    draw.rounded_rectangle(rect, radius=radius, fill=fill, outline=(255, 255, 255, 70), width=1)


def draw_transcript_pane(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], title: str, lines: Iterable[str], accent: tuple[int, int, int]) -> None:
    draw_card(draw, rect, fill=(240, 247, 248, 240), radius=28)
    x1, y1, x2, _ = rect
    draw.rounded_rectangle((x1 + 28, y1 + 28, x1 + 42, y1 + 76), radius=7, fill=accent + (255,))
    draw.text((x1 + 62, y1 + 26), title, font=font(34), fill=(24, 34, 38, 255))
    y = y1 + 98
    for line in lines:
        draw.text((x1 + 36, y), line, font=font(31), fill=(40, 55, 60, 255))
        y += 56
    draw.rounded_rectangle((x2 - 160, y1 + 30, x2 - 34, y1 + 74), radius=20, fill=(19, 27, 33, 24))
    draw.text((x2 - 132, y1 + 38), "복사", font=font(24), fill=(72, 93, 99, 255))


def draw_main_workspace(path: Path) -> None:
    bg = cover(Image.open(BG_ROOT / "01-main-workspace-bg.png"), SIZE).convert("RGBA")
    draw_gradient(bg, 96, 108)
    draw = ImageDraw.Draw(bg)
    draw.text((170, 126), "Mac 소리를 바로 기록하고 번역", font=font(76), fill=(248, 252, 252, 255))
    draw.text((174, 226), "회의, 강의, 영상 오디오를 원문과 번역으로 나란히 확인하세요.", font=font(36), fill=(202, 220, 225, 255))
    pill(draw, (176, 306), "로컬 중심 처리", (29, 127, 116, 224))
    pill(draw, (424, 306), "Apple Speech", (37, 85, 124, 224))
    pill(draw, (646, 306), "Translation", (34, 105, 92, 224))

    rect = (280, 460, 2600, 1590)
    draw = draw_app_window(bg, rect, active="실시간 번역")
    x1, y1, x2, _ = rect
    content_x = x1 + 438
    draw.text((content_x, y1 + 124), "실시간 기록 작업 공간", font=font(45), fill=(240, 248, 250, 255))
    draw.text((content_x, y1 + 184), "English → 한국어 · 캡처 중", font=font(28), fill=(151, 210, 202, 255))
    draw.rounded_rectangle((x2 - 436, y1 + 128, x2 - 118, y1 + 204), radius=32, fill=(40, 152, 134, 255))
    draw.text((x2 - 386, y1 + 146), "일시정지", font=font(30), fill=(250, 255, 255, 255))

    pane_top = y1 + 260
    draw_transcript_pane(
        draw,
        (content_x, pane_top, content_x + 820, pane_top + 590),
        "원문",
        [
            "Today we are looking at how live",
            "captions can help you follow a",
            "technical lecture while you keep",
            "notes on the same Mac.",
            "",
            "The audio stays on this device.",
        ],
        (49, 138, 210),
    )
    draw_transcript_pane(
        draw,
        (content_x + 874, pane_top, x2 - 72, pane_top + 590),
        "번역",
        [
            "오늘은 실시간 자막이 기술 강의를",
            "따라가며 같은 Mac에서 메모하는 데",
            "어떻게 도움이 되는지 살펴봅니다.",
            "",
            "오디오는 이 기기 중심으로 처리됩니다.",
        ],
        (39, 148, 126),
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(path, quality=96)


def draw_floating_captions(path: Path) -> None:
    bg = cover(Image.open(BG_ROOT / "02-floating-captions-bg.png"), SIZE).convert("RGBA")
    draw_gradient(bg, 118, 154)
    draw = ImageDraw.Draw(bg)
    draw.text((170, 126), "화면 위에 뜨는 번역 자막", font=font(76), fill=(248, 252, 252, 255))
    draw.text((174, 226), "영상이나 강의를 보면서 흐름을 끊지 않고 따라갑니다.", font=font(36), fill=(214, 226, 228, 255))

    caption = (430, 1224, 2450, 1470)
    add_shadow(bg, caption, 42, blur=52, offset=(0, 26), alpha=124)
    bg.alpha_composite(rounded_rect_layer(bg.size, caption, 42, (8, 12, 16, 210), (255, 255, 255, 58), 2))
    draw = ImageDraw.Draw(bg)
    draw.text((caption[0] + 94, caption[1] + 52), "The speaker is explaining the key idea in context.", font=font(44), fill=(211, 225, 231, 220))
    draw.text((caption[0] + 94, caption[1] + 116), "발표자가 핵심 아이디어를 맥락 안에서 설명하고 있습니다.", font=font(58), fill=(255, 255, 255, 255))

    panel = (1710, 460, 2600, 1088)
    add_shadow(bg, panel, 34, blur=32, offset=(0, 18), alpha=90)
    bg.alpha_composite(rounded_rect_layer(bg.size, panel, 34, (246, 250, 250, 232), (255, 255, 255, 84), 1))
    draw = ImageDraw.Draw(bg)
    draw.text((panel[0] + 54, panel[1] + 54), "플로팅 자막", font=font(46), fill=(21, 32, 36, 255))
    draw.text((panel[0] + 56, panel[1] + 116), "표시 모드와 크기를 빠르게 조정", font=font(30), fill=(81, 101, 108, 255))
    modes = ["원문", "원문 + 번역", "번역"]
    y = panel[1] + 204
    for mode in modes:
        selected = mode == "원문 + 번역"
        fill = (33, 139, 124, 255) if selected else (229, 236, 237, 255)
        color = (255, 255, 255, 255) if selected else (48, 65, 70, 255)
        draw.rounded_rectangle((panel[0] + 54, y, panel[2] - 54, y + 76), radius=26, fill=fill)
        draw.text((panel[0] + 86, y + 20), mode, font=font(30), fill=color)
        y += 98
    draw.text((panel[0] + 56, y + 22), "글자 크기", font=font(27), fill=(83, 103, 109, 255))
    draw.rounded_rectangle((panel[0] + 56, y + 72, panel[2] - 56, y + 84), radius=6, fill=(202, 216, 218, 255))
    draw.rounded_rectangle((panel[0] + 56, y + 72, panel[0] + 520, y + 84), radius=6, fill=(38, 145, 130, 255))
    path.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(path, quality=96)


def draw_library(path: Path) -> None:
    bg = cover(Image.open(BG_ROOT / "03-transcript-library-bg.png"), SIZE).convert("RGBA")
    draw_gradient(bg, 56, 92)
    draw = ImageDraw.Draw(bg)
    draw.text((170, 126), "기록은 Mac 안에 차곡차곡", font=font(76), fill=(24, 35, 39, 255))
    draw.text((174, 226), "자동 저장된 원문과 번역을 다시 열고, 수정하고, 정리하세요.", font=font(36), fill=(74, 92, 98, 255))

    rect = (300, 420, 2580, 1580)
    draw = draw_app_window(bg, rect, active="저장된 기록")
    x1, y1, x2, _ = rect
    content_x = x1 + 438
    draw.text((content_x, y1 + 126), "저장된 기록 관리", font=font(48), fill=(239, 248, 249, 255))
    draw.text((content_x, y1 + 190), "Application Support 컨테이너에 로컬 텍스트로 저장", font=font(29), fill=(161, 203, 199, 255))

    list_rect = (content_x, y1 + 270, content_x + 690, y1 + 942)
    editor_rect = (content_x + 738, y1 + 270, x2 - 74, y1 + 942)
    draw_card(draw, list_rect, fill=(241, 247, 248, 242), radius=30)
    draw_card(draw, editor_rect, fill=(241, 247, 248, 242), radius=30)
    draw.text((list_rect[0] + 36, list_rect[1] + 32), "최근 기록", font=font(34), fill=(27, 39, 43, 255))
    sessions = [
        ("회의_제품-데모.txt", "오늘 14:22 · 원문 + 번역"),
        ("강의_음성인식-개요.txt", "어제 21:10 · 번역"),
        ("영상_인터뷰-요약.txt", "5월 8일 · 원문"),
    ]
    y = list_rect[1] + 104
    for index, (title, subtitle) in enumerate(sessions):
        selected = index == 0
        fill = (222, 240, 237, 255) if selected else (255, 255, 255, 130)
        draw.rounded_rectangle((list_rect[0] + 28, y, list_rect[2] - 28, y + 118), radius=22, fill=fill)
        draw.text((list_rect[0] + 58, y + 26), title, font=font(29), fill=(26, 42, 45, 255))
        draw.text((list_rect[0] + 58, y + 67), subtitle, font=font(23), fill=(93, 116, 121, 255))
        y += 140
    draw.text((editor_rect[0] + 42, editor_rect[1] + 36), "회의_제품-데모.txt", font=font(35), fill=(26, 38, 42, 255))
    body = [
        "원문",
        "We can keep captions visible while reviewing the demo.",
        "",
        "번역",
        "데모를 확인하는 동안 자막을 계속 보이게 둘 수 있습니다.",
        "",
        "중요한 대화와 번역은 앱 안에서 다시 열어 볼 수 있습니다.",
    ]
    y = editor_rect[1] + 112
    for line in body:
        draw.text((editor_rect[0] + 46, y), line, font=font(30), fill=(42, 58, 62, 255) if line not in ["원문", "번역"] else (31, 131, 117, 255))
        y += 52
    path.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(path, quality=96)


def draw_privacy(path: Path) -> None:
    bg = cover(Image.open(BG_ROOT / "04-privacy-settings-bg.png"), SIZE).convert("RGBA")
    draw_gradient(bg, 28, 78)
    draw = ImageDraw.Draw(bg)
    draw.text((170, 126), "서버 없이, 필요한 권한만", font=font(76), fill=(26, 38, 42, 255))
    draw.text((174, 226), "계정, 광고, 분석 SDK 없이 macOS 시스템 프레임워크 중심으로 동작합니다.", font=font(36), fill=(74, 94, 100, 255))

    panel = (1490, 372, 2594, 1484)
    add_shadow(bg, panel, 40, blur=44, offset=(0, 28), alpha=90)
    bg.alpha_composite(rounded_rect_layer(bg.size, panel, 40, (247, 251, 250, 236), (255, 255, 255, 92), 2))
    draw = ImageDraw.Draw(bg)
    draw.text((panel[0] + 64, panel[1] + 66), "개인정보 중심 설정", font=font(50), fill=(25, 37, 41, 255))
    draw.text((panel[0] + 66, panel[1] + 132), "AirTranslate가 요구하는 권한은 기능에 직접 연결됩니다.", font=font(29), fill=(86, 106, 111, 255))
    checks = [
        ("화면 기록", "ScreenCaptureKit 시스템 오디오 캡처에 필요"),
        ("시스템 오디오 녹음", "Mac에서 재생되는 소리를 기록"),
        ("음성 인식", "캡처된 오디오를 실시간 텍스트로 변환"),
        ("로컬 저장", "기록은 앱 컨테이너 안에 보관"),
    ]
    y = panel[1] + 238
    for title, desc in checks:
        draw.ellipse((panel[0] + 68, y + 8, panel[0] + 118, y + 58), fill=(35, 142, 126, 255))
        draw.line((panel[0] + 82, y + 34, panel[0] + 96, y + 48, panel[0] + 112, y + 20), fill=(255, 255, 255, 255), width=6)
        draw.text((panel[0] + 148, y), title, font=font(34), fill=(27, 40, 44, 255))
        draw.text((panel[0] + 148, y + 46), desc, font=font(26), fill=(91, 111, 116, 255))
        y += 136
    draw.rounded_rectangle((panel[0] + 66, panel[3] - 178, panel[2] - 66, panel[3] - 72), radius=32, fill=(26, 38, 42, 255))
    draw.text((panel[0] + 106, panel[3] - 144), "계정 없음 · 광고 없음 · 자체 서버 없음", font=font(32), fill=(246, 252, 252, 255))

    path.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(path, quality=96)


def main() -> None:
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    draw_main_workspace(OUT_ROOT / "01-main-workspace-2880x1800.png")
    draw_floating_captions(OUT_ROOT / "02-floating-captions-2880x1800.png")
    draw_library(OUT_ROOT / "03-saved-transcripts-2880x1800.png")
    draw_privacy(OUT_ROOT / "04-privacy-settings-2880x1800.png")


if __name__ == "__main__":
    main()
