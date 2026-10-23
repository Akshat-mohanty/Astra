import os
import sys
import struct
import gzip
import base64

def patch_resources_pak():
    pak_path = '/Applications/Astra.app/Contents/Frameworks/Thorium Framework.framework/Versions/138.0.7204.303/Resources/resources.pak'
    backup_path = pak_path + '.bak'

    if not os.path.exists(backup_path):
        with open(pak_path, 'rb') as f_in, open(backup_path, 'wb') as f_out:
            f_out.write(f_in.read())
        print(f"Created backup at {backup_path}")

    # 1. Read base64 logo and favicon
    logo_path = '/Users/akshatmohanty/Astra/src/newtab/astra_logo.png'
    with open(logo_path, 'rb') as f:
        logo_b64 = base64.b64encode(f.read()).decode('utf-8')
    data_uri = f"data:image/png;base64,{logo_b64}"

    icon_32_path = '/Users/akshatmohanty/Astra/src/newtab/icons/icon_32.png'
    with open(icon_32_path, 'rb') as f:
        favicon_b64 = base64.b64encode(f.read()).decode('utf-8')
    favicon_uri = f"data:image/png;base64,{favicon_b64}"

    # 2. Build complete self-contained New Tab Page HTML & JS (CSP compliant)
    newtab_html_path = '/Users/akshatmohanty/Astra/src/newtab/index.html'
    newtab_js_path = '/Users/akshatmohanty/Astra/src/newtab/newtab.js'

    with open(newtab_html_path, 'r', encoding='utf-8') as f:
        html_content = f.read()

    with open(newtab_js_path, 'r', encoding='utf-8') as f:
        js_content = f.read()

    # Replace local asset paths with data URIs and CSP-compliant module script
    html_content = html_content.replace('href="favicon.png"', f'href="{favicon_uri}"')
    html_content = html_content.replace('src="astra_logo.png"', f'src="{data_uri}"')
    html_content = html_content.replace('<script src="newtab.js"></script>', '<script type="module" src="new_tab_page.js"></script>')

    compressed_html = gzip.compress(html_content.encode('utf-8'))
    compressed_js = gzip.compress(js_content.encode('utf-8'))

    # Read original pak
    with open(backup_path, 'rb') as f:
        orig_data = f.read()

    header = orig_data[:12]
    v, enc, num_res, num_alias = struct.unpack('<IIHH', header)

    res_table_len = (num_res + 1) * 6
    res_table_bytes = orig_data[12:12 + res_table_len]
    res_entries = []
    for i in range(num_res + 1):
        rid, offset = struct.unpack('<HI', res_table_bytes[i*6:(i+1)*6])
        res_entries.append((rid, offset))

    alias_offset = 12 + res_table_len
    alias_table_len = num_alias * 4
    alias_bytes = orig_data[alias_offset:alias_offset + alias_table_len]

    payloads = {}
    for i in range(num_res):
        rid, offset = res_entries[i]
        next_offset = res_entries[i+1][1]
        payloads[rid] = orig_data[offset:next_offset]

    # Replace Resource ID 23390 (HTML), 23392 (JS), and favicon/logo IDs in resources.pak
    payloads[23390] = compressed_html
    payloads[23392] = compressed_js
    print("Replaced Resource ID 23390 (HTML) and 23392 (JS) with CSP compliance")

    # Replace Resource ID 25185 (Settings HTML) and 25186 (Settings JS) with Astra Custom Settings
    settings_dir = '/Users/akshatmohanty/Astra/src/settings'
    if os.path.exists(f'{settings_dir}/settings.html'):
        with open(f'{settings_dir}/settings.html', 'r', encoding='utf-8') as f:
            s_html = f.read()
        with open(f'{settings_dir}/settings.css', 'r', encoding='utf-8') as f:
            s_css = f.read()
        with open(f'{settings_dir}/settings.js', 'r', encoding='utf-8') as f:
            s_js = f.read()

        # Inline CSS for instant dark mode render and zero CSP issues
        inlined_s_html = s_html.replace(
            '<link rel="stylesheet" href="settings.css">',
            f'<style>\n{s_css}\n</style>'
        )
        payloads[25185] = gzip.compress(inlined_s_html.encode('utf-8'))
        payloads[25186] = gzip.compress(s_js.encode('utf-8'))
        print("Replaced Resource ID 25185 (Settings HTML) and 25186 (Settings JS) with Astra Custom Settings!")

    icons_dir = '/Users/akshatmohanty/Astra/src/newtab/icons'
    if os.path.exists(f'{icons_dir}/icon_16.png') and 17186 in payloads:
        with open(f'{icons_dir}/icon_16.png', 'rb') as f:
            payloads[17186] = f.read()
        print("Replaced Resource ID 17186 (16px logo) in resources.pak")

    if os.path.exists(f'{icons_dir}/icon_24.png') and 17187 in payloads:
        with open(f'{icons_dir}/icon_24.png', 'rb') as f:
            payloads[17187] = f.read()
        print("Replaced Resource ID 17187 (24px logo) in resources.pak")

    # Reconstruct PAK
    new_header = struct.pack('<IIHH', v, enc, num_res, num_alias)
    start_of_data = 12 + (num_res + 1) * 6 + num_alias * 4

    curr_offset = start_of_data
    new_res_table = bytearray()
    data_blob = bytearray()

    for rid, _ in res_entries[:num_res]:
        new_res_table.extend(struct.pack('<HI', rid, curr_offset))
        p = payloads[rid]
        data_blob.extend(p)
        curr_offset += len(p)

    new_res_table.extend(struct.pack('<HI', 0, curr_offset))

    new_pak_data = new_header + bytes(new_res_table) + alias_bytes + bytes(data_blob)

    with open(pak_path, 'wb') as f:
        f.write(new_pak_data)

    print(f"Successfully patched {pak_path}! New size: {len(new_pak_data)} bytes")

def patch_pak_generic(pak_path, replacements):
    backup_path = pak_path + '.bak'
    if not os.path.exists(backup_path):
        with open(pak_path, 'rb') as f_in, open(backup_path, 'wb') as f_out:
            f_out.write(f_in.read())
        print(f"Created backup at {backup_path}")

    with open(backup_path, 'rb') as f:
        orig_data = f.read()

    header = orig_data[:12]
    v, enc, num_res, num_alias = struct.unpack('<IIHH', header)

    res_table_len = (num_res + 1) * 6
    res_table_bytes = orig_data[12:12 + res_table_len]
    res_entries = []
    for i in range(num_res + 1):
        rid, offset = struct.unpack('<HI', res_table_bytes[i*6:(i+1)*6])
        res_entries.append((rid, offset))

    alias_offset = 12 + res_table_len
    alias_table_len = num_alias * 4
    alias_bytes = orig_data[alias_offset:alias_offset + alias_table_len]

    payloads = {}
    for i in range(num_res):
        rid, offset = res_entries[i]
        next_offset = res_entries[i+1][1]
        payloads[rid] = orig_data[offset:next_offset]

    count = 0
    for rid, new_data in replacements.items():
        if rid in payloads:
            payloads[rid] = new_data
            count += 1

    # Reconstruct PAK
    new_header = struct.pack('<IIHH', v, enc, num_res, num_alias)
    start_of_data = 12 + (num_res + 1) * 6 + num_alias * 4

    curr_offset = start_of_data
    new_res_table = bytearray()
    data_blob = bytearray()

    for rid, _ in res_entries[:num_res]:
        new_res_table.extend(struct.pack('<HI', rid, curr_offset))
        p = payloads[rid]
        data_blob.extend(p)
        curr_offset += len(p)

    new_res_table.extend(struct.pack('<HI', 0, curr_offset))

    new_pak_data = new_header + bytes(new_res_table) + alias_bytes + bytes(data_blob)

    with open(pak_path, 'wb') as f:
        f.write(new_pak_data)

    print(f"Successfully patched {os.path.basename(pak_path)}! Replaced {count} resources. New size: {len(new_pak_data)} bytes")

def main():
    icons_dir = '/Users/akshatmohanty/Astra/src/newtab/icons'
    with open(f'{icons_dir}/icon_16.png', 'rb') as f:
        icon_16 = f.read()
    with open(f'{icons_dir}/icon_24.png', 'rb') as f:
        icon_24 = f.read()
    with open(f'{icons_dir}/icon_32.png', 'rb') as f:
        icon_32 = f.read()
    with open(f'{icons_dir}/icon_64.png', 'rb') as f:
        icon_64 = f.read()
    with open(f'{icons_dir}/icon_128.png', 'rb') as f:
        icon_128 = f.read()

    # 1. Patch resources.pak
    patch_resources_pak()

    # 2. Patch chrome_100_percent.pak
    base_res = '/Applications/Astra.app/Contents/Frameworks/Thorium Framework.framework/Versions/138.0.7204.303/Resources'
    p100 = f'{base_res}/chrome_100_percent.pak'
    replacements_100 = {
        263: icon_16,
        356: icon_16,
        17340: icon_32,
        55528: icon_16,
        55529: icon_32,
        55530: icon_32,
        55531: icon_64,
    }
    patch_pak_generic(p100, replacements_100)

    # 3. Patch chrome_200_percent.pak
    p200 = f'{base_res}/chrome_200_percent.pak'
    replacements_200 = {
        263: icon_32,
        356: icon_32,
        17340: icon_64,
        55528: icon_32,
        55529: icon_64,
        55530: icon_64,
        55531: icon_128,
    }
    patch_pak_generic(p200, replacements_200)

if __name__ == '__main__':
    main()
