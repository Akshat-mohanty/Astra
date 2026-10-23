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
import sys

FRAMEWORK_PATH = '/Applications/Astra.app/Contents/Frameworks/Thorium Framework.framework/Versions/138.0.7204.303/Thorium Framework'
BACKUP_PATH = FRAMEWORK_PATH + '.orig'

OFFSET = 0x119ac8c
ORIG_HEX = 'f657bda9f44f01a9'
PATCH_BYTES = bytes.fromhex('00008052c0035fd6')

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
