#!/usr/bin/env python3
"""
patch_framework.py

Patches Thorium Framework to permanently hide the native Omnibox toolbar
while preserving the native horizontal tab strip on top.

Function: BrowserView::IsToolbarVisible()
File offset: 0x119ac8c
Original: f6 57 bd a9 f4 4f 01 a9  (stp x22, x21, [sp, #-0x30]!; stp x20, x19, [sp, #0x10])
Patch:    00 00 80 52 c0 03 5f d6  (mov w0, #0; ret)
"""

import os
import subprocess
import struct
import sys

FRAMEWORK_PATH = '/Applications/Astra.app/Contents/Frameworks/Thorium Framework.framework/Versions/138.0.7204.303/Thorium Framework'
BACKUP_PATH = FRAMEWORK_PATH + '.orig'

OFFSET = 0x119ac8c
ORIG_HEX = 'f657bda9f44f01a9'
PATCH_BYTES = bytes.fromhex('00008052c0035fd6')

# kGlobeIcon vector path replacement with exact Astra constellation emblem
REP1_PATH_OFFSET = 0xbb532e0
REP1_STRUCT_PTR_OFFSET = 0xd0d6910
REP1_STRUCT_SIZE_OFFSET = 0xd0d6910 + 8

REP2_PATH_OFFSET = 0xc0859f8
REP2_STRUCT_PTR_OFFSET = 0xd255d98
REP2_STRUCT_SIZE_OFFSET = 0xd255d98 + 8

def build_constellation_blob():
    blob = bytearray()
    count = 0
    def emit_cmd(c):
        nonlocal count
        blob.extend(struct.pack('<I', c))
        count += 1
    def emit_flt(v):
        nonlocal count
        blob.extend(struct.pack('<f', float(v)))
        count += 1

    emit_cmd(28) # CANVAS_DIMENSIONS
    emit_flt(24.0)

    def add_star(cx, cy, rx=0.8, ry=0.8):
        emit_cmd(7) # MOVE_TO
        emit_flt(cx); emit_flt(cy - ry)
        emit_cmd(11) # LINE_TO
        emit_flt(cx + rx); emit_flt(cy)
        emit_cmd(11)
        emit_flt(cx); emit_flt(cy + ry)
        emit_cmd(11)
        emit_flt(cx - rx); emit_flt(cy)
        emit_cmd(27) # CLOSE

    def add_stroke(p1, p2, w=0.36):
        x1, y1 = p1
        x2, y2 = p2
        dx, dy = x2 - x1, y2 - y1
        l = (dx*dx + dy*dy)**0.5
        if l == 0: return
        nx = -dy / l * w
        ny = dx / l * w
        emit_cmd(7)
        emit_flt(x1 - nx); emit_flt(y1 - ny)
        emit_cmd(11)
        emit_flt(x1 + nx); emit_flt(y1 + ny)
        emit_cmd(11)
        emit_flt(x2 + nx); emit_flt(y2 + ny)
        emit_cmd(11)
        emit_flt(x2 - nx); emit_flt(y2 - ny)
        emit_cmd(27)

    # 1. Outer Diamond Perimeter (6 isometric hexagon edges)
    outer = [(12.0, 2.0), (20.5, 7.0), (20.5, 17.0), (12.0, 22.0), (3.5, 17.0), (3.5, 7.0)]
    for i in range(6):
        add_stroke(outer[i], outer[(i+1)%6], w=0.35)

    # 2. Central Chevron "A" Core
    # Apex at (12.0, 6.8), feet at (7.8, 14.8) and (16.2, 14.8)
    add_stroke((12.0, 6.8), (7.8, 14.8), w=0.55)
    add_stroke((12.0, 6.8), (16.2, 14.8), w=0.55)
    # Horizontal crossbar
    add_stroke((9.2, 12.8), (14.8, 12.8), w=0.45)

    # 3. Constellation Facet Spoke Lines
    add_stroke((12.0, 2.0), (12.0, 6.8), w=0.35)  # Top spoke
    add_stroke((12.0, 6.8), (3.5, 7.0), w=0.32)   # Upper left spoke
    add_stroke((12.0, 6.8), (20.5, 7.0), w=0.32)  # Upper right spoke
    add_stroke((7.8, 14.8), (3.5, 17.0), w=0.32)  # Lower left spoke
    add_stroke((16.2, 14.8), (20.5, 17.0), w=0.32) # Lower right spoke
    add_stroke((7.8, 14.8), (12.0, 22.0), w=0.35) # Bottom left spoke
    add_stroke((16.2, 14.8), (12.0, 22.0), w=0.35) # Bottom right spoke

    # 4. Constellation Stars at Nodes (6 stars, total elements = 286 <= 289)
    stars = [
        (12.0, 2.0),  # Top Tip
        (12.0, 22.0), # Bottom Tip
        (12.0, 6.8),  # Chevron Apex Star
        (7.8, 14.8),  # Left Foot Star
        (16.2, 14.8), # Right Foot Star
        (12.0, 12.8), # Center Star
    ]
    for sx, sy in stars:
        add_star(sx, sy, 0.8, 0.8)

    assert count <= 289, f"Blob count {count} exceeds 289 limit!"
    return bytes(blob), count

def main():
    if not os.path.exists(FRAMEWORK_PATH):
        print(f"Error: Framework not found at {FRAMEWORK_PATH}")
        sys.exit(1)

    # 1. Create backup if not exists
    if not os.path.exists(BACKUP_PATH):
        import shutil
        shutil.copyfile(FRAMEWORK_PATH, BACKUP_PATH)
        print(f"Created backup at {BACKUP_PATH}")

    # 2. Check and patch
    with open(FRAMEWORK_PATH, 'r+b') as f:
        f.seek(OFFSET)
        current = f.read(8)
        if current == PATCH_BYTES:
            print("Thorium Framework is already patched for hidden toolbar.")
        elif current.hex() == ORIG_HEX:
            f.seek(OFFSET)
            f.write(PATCH_BYTES)
            print(f"Successfully patched BrowserView::IsToolbarVisible() at offset {hex(OFFSET)}!")
        else:
            print(f"Warning: Unexpected bytes at {hex(OFFSET)}: {current.hex()}")
            print("Attempting patch anyway...")
            f.seek(OFFSET)
            f.write(PATCH_BYTES)
            print("Patch applied.")

        # Patch kGlobeIcon vector paths
        blob, count = build_constellation_blob()

        # Patch Rep 1
        f.seek(REP1_PATH_OFFSET)
        f.write(blob)
        # Restore Rep 1 struct pointer to REP1_PATH_OFFSET
        f.seek(REP1_STRUCT_PTR_OFFSET)
        f.write(struct.pack('<Q', REP1_PATH_OFFSET))
        f.seek(REP1_STRUCT_SIZE_OFFSET)
        f.write(struct.pack('<Q', count))

        # Patch Rep 2
        f.seek(REP2_PATH_OFFSET)
        f.write(blob)
        # Restore Rep 2 struct pointer to REP2_PATH_OFFSET
        f.seek(REP2_STRUCT_PTR_OFFSET)
        f.write(struct.pack('<Q', REP2_PATH_OFFSET))
        f.seek(REP2_STRUCT_SIZE_OFFSET)
        f.write(struct.pack('<Q', count))

        print(f"Successfully patched kGlobeIcon with exact Astra constellation emblem ({count} elements at {hex(REP1_PATH_OFFSET)} and {hex(REP2_PATH_OFFSET)})!")

    # 3. Re-sign framework and app
    print("Re-signing framework and app...")
    subprocess.run([
        'codesign', '--force', '--sign', '-',
        FRAMEWORK_PATH
    ], check=True)
    subprocess.run([
        'codesign', '--force', '--sign', '-',
        '/Applications/Astra.app/Contents/Frameworks/Thorium Framework.framework'
    ], check=True)
    subprocess.run([
        'codesign', '--force', '--deep', '--sign', '-',
        '/Applications/Astra.app'
    ], check=True)
    print("Code signing complete!")

if __name__ == '__main__':
    main()
