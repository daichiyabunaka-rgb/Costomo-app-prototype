"""コスとも！配布用アプリアイコン（1024px）を作るスクリプト。
Pillow でフラットデザインのマスカレードマスク（コスプレの象徴）を描く。生成物:
  - app/assets/icon/app_icon.png      （flutter_launcher_icons のソース）
"""
from PIL import Image, ImageDraw

SIZE = 1024
BG = (240, 235, 247)        # ラベンダー（シリーズ共通の落ち着いた背景色）
MASK = (109, 88, 168)       # 深い紫（衣装・ヴィラン系の落ち着いた色）
MASK_DARK = (89, 70, 143)   # マスクの縁取り
SPARK = (245, 196, 66)      # キラキラ（ステージ・スポットライト）
EYE_HOLE = BG               # 目の穴は背景色で抜く


def rounded(im: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", im.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def draw_mask():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # 背景（角丸ラベンダー）
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=192, fill=BG + (255,))

    # マスクの左右のリボン（マスカレードマスクの紐）
    ribbon = MASK_DARK + (255,)
    d.polygon([(120, 470), (40, 430), (24, 500), (110, 522)], fill=ribbon)
    d.polygon([(904, 470), (984, 430), (1000, 500), (914, 522)], fill=ribbon)

    # マスク本体（横長の角丸帯）
    m_l, m_t, m_r, m_b = 130, 380, 894, 680
    d.rounded_rectangle([m_l, m_t, m_r, m_b], radius=150, fill=MASK + (255,))
    # 縁の上下の膨らみ（目元のふくらみ）
    for cx in (352, 672):
        d.ellipse([cx - 190, m_t - 46, cx + 190, m_t + 90], fill=MASK + (255,))
        d.ellipse([cx - 150, m_t - 30, cx + 150, m_t + 66], fill=MASK_DARK + (255,))

    # 目の穴（アーモンド形: 楕円で近似）
    for cx in (352, 672):
        d.ellipse([cx - 150, 452, cx + 150, 596], fill=EYE_HOLE + (255,))

    # 鼻筋のくびれ（中央の切れ込みを暗色で表現）
    d.rounded_rectangle([492, 428, 532, 620], radius=20, fill=MASK_DARK + (255,))

    # キラッ（星型: 4本の光条）
    def star(cx, cy, r, w, color):
        pts = []
        for i in range(8):
            ang = i * 45
            rr = r if i % 2 == 0 else w
            import math
            pts.append((cx + rr * math.cos(math.radians(ang)),
                        cy + rr * math.sin(math.radians(ang))))
        d.polygon(pts, fill=color + (255,))

    star(800, 250, 74, 22, SPARK)
    star(232, 288, 40, 14, SPARK)
    star(878, 368, 26, 10, SPARK)

    return im


if __name__ == "__main__":
    im = draw_mask()
    im = rounded(im, 192)
    out = r"..\app\assets\icon\app_icon.png"
    im.save(out)
    print("saved:", out)
