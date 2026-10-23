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

# kGlobeIcon vector path replacement with Astra constellation matrix
REP1_PATH_OFFSET = 0xbb532e0
REP1_STRUCT_SIZE_OFFSET = 0xd0d6910 + 8

REP2_PATH_OFFSET = 0xc0859f8
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

    # 1. CANVAS_DIMENSIONS, 24
    emit_cmd(28)
    emit_flt(24.0)

    center = (12.0, 12.0)
    ring = [
        (12.0, 4.5),
        (18.5, 8.25),
        (18.5, 15.75),
        (12.0, 19.5),
        (5.5, 15.75),
        (5.5, 8.25)
    ]
    all_nodes = [center] + ring

    # 12 connecting lines: 6 spokes from center to ring, 6 perimeter edges
    edges = []
    for p in ring:
        edges.append((center, p))
    for i in range(6):
        edges.append((ring[i], ring[(i+1)%6]))

    sw = 0.5  # half stroke width
    for p1, p2 in edges:
        x1, y1 = p1
        x2, y2 = p2
        dx = x2 - x1
        dy = y2 - y1
        length = (dx*dx + dy*dy)**0.5
        if length == 0: continue
        nx = -dy / length * sw
        ny = dx / length * sw
        emit_cmd(7)  # MOVE_TO
        emit_flt(x1 - nx)
        emit_flt(y1 - ny)
        emit_cmd(11) # LINE_TO
        emit_flt(x1 + nx)
        emit_flt(y1 + ny)
        emit_cmd(11) # LINE_TO
        emit_flt(x2 + nx)
        emit_flt(y2 + ny)
        emit_cmd(11) # LINE_TO
        emit_flt(x2 - nx)
        emit_flt(y2 - ny)
        emit_cmd(27) # CLOSE

    # 7 diamond stars at each node
    r = 1.2
    for x, y in all_nodes:
        emit_cmd(7)
        emit_flt(x)
        emit_flt(y - r)
        emit_cmd(11)
        emit_flt(x + r)
        emit_flt(y)
        emit_cmd(11)
        emit_flt(x)
        emit_flt(y + r)
        emit_cmd(11)
        emit_flt(x - r)
        emit_flt(y)
        emit_cmd(27)

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
        f.seek(REP1_STRUCT_SIZE_OFFSET)
        f.write(struct.pack('<Q', count))
        # Patch Rep 2
        f.seek(REP2_PATH_OFFSET)
        f.write(blob)
        f.seek(REP2_STRUCT_SIZE_OFFSET)
        f.write(struct.pack('<Q', count))
        print(f"Successfully patched kGlobeIcon with Astra constellation vector ({count} elements)!")

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
