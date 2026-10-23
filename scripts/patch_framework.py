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

# kGlobeIcon vector path replacement with exact Astra constellation matrix from screenshot
NEW_PATH_OFFSET = 0xbd2e66a  # Zero padding area in __const (size 5138 bytes)

REP1_STRUCT_PTR_OFFSET = 0xd0d6910
REP1_STRUCT_SIZE_OFFSET = 0xd0d6910 + 8

REP2_STRUCT_PTR_OFFSET = 0xd255d98
REP2_STRUCT_SIZE_OFFSET = 0xd255d98 + 8

def build_constellation_blob():
    from PIL import Image
    icon_path = '/Users/akshatmohanty/Astra/src/newtab/icons/icon_24.png'
    t = Image.open(icon_path).convert('L')
    small = t.resize((24, 24), Image.Resampling.LANCZOS)

    # Build mask with open hexagonal cells and local maxima constellation dots
    mask = Image.new('L', (24, 24), 0)
    for y in range(24):
        for x in range(24):
            v = small.getpixel((x, y))
            if v > 68:
                mask.putpixel((x, y), 255)
            elif v > 38:
                is_max = True
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        if 0 <= x+dx < 24 and 0 <= y+dy < 24:
                            if small.getpixel((x+dx, y+dy)) > v:
                                is_max = False
                                break
                    if not is_max: break
                if is_max:
                    mask.putpixel((x, y), 255)

    spans = []
    for y in range(24):
        in_span = False
        start_x = 0
        for x in range(24):
            if mask.getpixel((x, y)) > 0:
                if not in_span:
                    in_span = True
                    start_x = x
            else:
                if in_span:
                    in_span = False
                    spans.append((start_x, y, x, y + 1))
        if in_span:
            spans.append((start_x, y, 24, y + 1))

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

    for x1, y1, x2, y2 in spans:
        emit_cmd(7) # MOVE_TO
        emit_flt(x1)
        emit_flt(y1)
        emit_cmd(11) # LINE_TO
        emit_flt(x2)
        emit_flt(y1)
        emit_cmd(11) # LINE_TO
        emit_flt(x2)
        emit_flt(y2)
        emit_cmd(11) # LINE_TO
        emit_flt(x1)
        emit_flt(y2)
        emit_cmd(27) # CLOSE

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
        # Write blob to NEW_PATH_OFFSET
        f.seek(NEW_PATH_OFFSET)
        f.write(blob)
        # Update Rep 1 pointer and size
        f.seek(REP1_STRUCT_PTR_OFFSET)
        f.write(struct.pack('<Q', NEW_PATH_OFFSET))
        f.seek(REP1_STRUCT_SIZE_OFFSET)
        f.write(struct.pack('<Q', count))
        # Update Rep 2 pointer and size
        f.seek(REP2_STRUCT_PTR_OFFSET)
        f.write(struct.pack('<Q', NEW_PATH_OFFSET))
        f.seek(REP2_STRUCT_SIZE_OFFSET)
        f.write(struct.pack('<Q', count))
        print(f"Successfully patched kGlobeIcon with exact Astra constellation vector ({count} elements at {hex(NEW_PATH_OFFSET)})!")

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
