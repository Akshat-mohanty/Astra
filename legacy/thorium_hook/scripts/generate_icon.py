import os
import subprocess
from PIL import Image, ImageDraw

def create_astra_icon():
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    iconset_dir = "/tmp/Astra.iconset"
    os.makedirs(iconset_dir, exist_ok=True)

    base_size = 1024
    img = Image.new("RGBA", (base_size, base_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Outer rounded background / badge
    margin = 48
    draw.ellipse(
        [margin, margin, base_size - margin, base_size - margin],
        fill=(15, 23, 42, 255),
        outline=(99, 102, 241, 180),
        width=12
    )

    # Glow layer
    for r in range(40, 0, -4):
        alpha = int(120 * (1 - r / 40.0))
        draw.ellipse(
            [margin + 40 - r, margin + 40 - r, base_size - margin - 40 + r, base_size - margin - 40 + r],
            outline=(139, 92, 246, alpha),
            width=3
        )

    # 4-pointed Astra Star
    center = base_size / 2
    outer_r = 380
    inner_r = 110

    # Star points: N, NE_inner, E, SE_inner, S, SW_inner, W, NW_inner
    points = [
        (center, center - outer_r),
        (center + inner_r, center - inner_r),
        (center + outer_r, center),
        (center + inner_r, center + inner_r),
        (center, center + outer_r),
        (center - inner_r, center + inner_r),
        (center - outer_r, center),
        (center - inner_r, center - inner_r)
    ]

    # Draw star with vibrant purple-indigo gradient approximation
    draw.polygon(points, fill=(139, 92, 246, 255))

    # Inner highlights
    inner_points = [
        (center, center - outer_r + 60),
        (center + inner_r - 20, center - inner_r + 20),
        (center + outer_r - 60, center),
        (center + inner_r - 20, center + inner_r - 20),
        (center, center + outer_r - 60),
        (center - inner_r + 20, center + inner_r - 20),
        (center - outer_r + 60, center),
        (center - inner_r + 20, center - inner_r + 20)
    ]
    draw.polygon(inner_points, fill=(236, 72, 153, 220))

    # Center sparkle
    draw.ellipse(
        [center - 50, center - 50, center + 50, center + 50],
        fill=(255, 255, 255, 255)
    )

    # Generate standard iconset files
    icon_specs = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for fname, sz in icon_specs:
        resized = img.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, fname))

    out_icns = "/Users/akshatmohanty/Astra/build/Astra.app/Contents/Resources/app.icns"
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", out_icns], check=True)
    print("Successfully generated:", out_icns)

if __name__ == "__main__":
    create_astra_icon()
