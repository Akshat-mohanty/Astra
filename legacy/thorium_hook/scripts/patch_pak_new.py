import os
import sys
import struct
import gzip
import base64
import re

def patch_resources_pak():
    pak_path = '/Applications/Astra.app/Contents/Frameworks/Thorium Framework.framework/Versions/138.0.7204.303/Resources/resources.pak'
    backup_path = pak_path + '.bak_new'

    if not os.path.exists(backup_path):
        with open(pak_path, 'rb') as f_in, open(backup_path, 'wb') as f_out:
            f_out.write(f_in.read())
        print(f"Created backup at {backup_path}")

    # Read original pak backup
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

    # 1. New Tab Page (Resource 23390 HTML, 23392 JS)
    logo_path = '/Users/akshatmohanty/Astra/src/newtab/astra_logo.png'
    with open(logo_path, 'rb') as f:
        logo_b64 = base64.b64encode(f.read()).decode('utf-8')
    data_uri = f"data:image/png;base64,{logo_b64}"

    icon_32_path = '/Users/akshatmohanty/Astra/src/newtab/icons/icon_32.png'
    with open(icon_32_path, 'rb') as f:
        favicon_b64 = base64.b64encode(f.read()).decode('utf-8')
    favicon_uri = f"data:image/png;base64,{favicon_b64}"

    newtab_html_path = '/Users/akshatmohanty/Astra/src/newtab/index.html'
    newtab_js_path = '/Users/akshatmohanty/Astra/src/newtab/newtab.js'

    with open(newtab_html_path, 'r', encoding='utf-8') as f:
        html_content = f.read()
    with open(newtab_js_path, 'r', encoding='utf-8') as f:
        js_content = f.read()

    html_content = html_content.replace('href="favicon.png"', f'href="{favicon_uri}"')
    html_content = html_content.replace('src="astra_logo.png"', f'src="{data_uri}"')
    html_content = html_content.replace('<script src="newtab.js"></script>', '<script type="module" src="new_tab_page.js"></script>')

    payloads[23390] = gzip.compress(html_content.encode('utf-8'))
    payloads[23392] = gzip.compress(js_content.encode('utf-8'))
    print("Patched Resource ID 23390 (HTML) and 23392 (JS)")

    # 2. Root-Level Settings WebUI Modifications - COMPLETELY REDESIGNED
    root_settings_html = """<!doctype html>
<html dir="$i18n{textdirection}" lang="$i18n{language}" class="loading">
<head>
  <meta charset="utf-8">
  <meta name="color-scheme" content="dark">
  <title>Settings</title>
  <base href="chrome://settings">
  <link rel="stylesheet" href="chrome://resources/css/md_colors.css">
  <style>
    html {
      overflow-x: hidden;
      touch-action: manipulation;
    }

    :root, [dark], html, body {
      --md-background-color: #0a0a0a !important;
      --cr-toolbar-background-color: #0a0a0a !important;
      --cr-card-background-color: #151515 !important;
      --cr-card-border-radius: 12px !important;
      --cr-primary-text-color: #ffffff !important;
      --cr-secondary-text-color: #9b9b9b !important;
      --cr-separator-color: rgba(255, 255, 255, 0.06) !important;
      --cr-separator-line: 1px solid rgba(255, 255, 255, 0.06) !important;
      --cr-focus-outline-color: rgba(255, 255, 255, 0.4) !important;
      --cr-checked-color: #ffffff !important;
      --cr-hover-background-color: rgba(255, 255, 255, 0.04) !important;
      --cr-active-background-color: rgba(255, 255, 255, 0.08) !important;
      --cr-toggle-checked-bar-color: rgba(255, 255, 255, 0.3) !important;
      --cr-toggle-checked-button-color: #000000 !important;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", Inter, Roboto, sans-serif !important;
    }

    html {
      background: #0a0a0a;
    }

    html,
    body {
      height: 100%;
      margin: 0;
      background: #0a0a0a;
    }

    settings-ui {
      --settings-menu-width: 0px;
    }

    cr-toolbar {
      display: none !important;
    }

    #main {
      padding-top: 0 !important;
    }

    settings-main {
      padding-top: 0 !important;
    }
  </style>
</head>
<body>
  <link rel="stylesheet" href="chrome://resources/css/text_defaults_md.css">
  <script type="module" src="settings.js"></script>
  <settings-ui></settings-ui>
</body>
</html>
"""
    payloads[25185] = gzip.compress(root_settings_html.encode('utf-8'))
    print("Redesigned Resource ID 25185 with completely new settings UI")

    # Resource 25188: shared.rollup.js (Route definitions)
    orig_shared = gzip.decompress(payloads[25188]).decode('utf-8')
    target_route = 'r.FONTS=r.APPEARANCE.createChild("/fonts")}'
    if target_route in orig_shared:
        patched_shared = orig_shared.replace(
            target_route,
            'r.FONTS=r.APPEARANCE.createChild("/fonts")}r.TABS=r.BASIC.createSection("/tabs","tabs","Tabs");'
        )
        payloads[25188] = gzip.compress(patched_shared.encode('utf-8'))
        print("Patched Resource ID 25188 (shared.rollup.js): Registered native route routes.TABS")
    else:
        print("Warning: target_route not found in Resource 25188")

    # Resource 25186: settings.js - Replace with completely new design
    orig_settings = gzip.decompress(payloads[25186]).decode('utf-8')

    # Read new settings component
    new_settings_path = '/Users/akshatmohanty/Astra/src/settings/new_settings.js'
    with open(new_settings_path, 'r', encoding='utf-8') as f:
        new_settings_code = f.read()

    tabs_page_path = '/Users/akshatmohanty/Astra/src/settings/tabs_page.js'
    with open(tabs_page_path, 'r', encoding='utf-8') as f:
        tabs_component_code = f.read()

    patched_settings = orig_settings

    # Remove menu items
    for pattern in [r'<a role="menuitem" id="people".*?</a>\s*', r'<a role="menuitem" href="/ai".*?</a>\s*', r'<a role="menuitem" id="system".*?</a>\s*']:
        m = re.search(pattern, patched_settings, re.DOTALL)
        if m:
            patched_settings = patched_settings.replace(m.group(0), '')
    
    patched_settings = patched_settings.replace(
        '<template is="dom-if" if="[[showPage_(pageVisibility.people)]]" restamp>',
        '<template is="dom-if" if="[[false]]" restamp>'
    )
    patched_settings = patched_settings.replace(
        '<template is="dom-if" if="[[showAiPageAiFeatureSection_]]" restamp>',
        '<template is="dom-if" if="[[false]]" restamp>'
    )
    
    # Change default route
    patched_settings = patched_settings.replace(
        'TOP_LEVEL_EQUIVALENT_ROUTE=loadTimeData.getBoolean("isGuest")?guestTopLevelRoute:routes.PEOPLE;',
        'TOP_LEVEL_EQUIVALENT_ROUTE=loadTimeData.getBoolean("isGuest")?guestTopLevelRoute:routes.BASIC;'
    )

    # Inject new settings component and tabs
    export_idx = patched_settings.rfind('export{')
    if export_idx != -1:
        patched_settings = (
            patched_settings[:export_idx]
            + '\n' + new_settings_code + '\n\n' + tabs_component_code + '\n'
            + patched_settings[export_idx:]
        )
        payloads[25186] = gzip.compress(patched_settings.encode('utf-8'))
        print("Patched Resource ID 25186 with completely new settings UI design")
    else:
        print("Warning: export statement not found in Resource 25186")

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

if __name__ == '__main__':
    patch_resources_pak()
