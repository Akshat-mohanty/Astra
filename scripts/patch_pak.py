import os
import sys
import struct
import gzip
import base64
import re

def patch_resources_pak():
    pak_path = '/Applications/Astra.app/Contents/Frameworks/Thorium Framework.framework/Versions/138.0.7204.303/Resources/resources.pak'
    backup_path = pak_path + '.bak'

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

    # 2. Root-Level Settings WebUI Modifications
    # Resource 25185: Chromium's Native Root Settings HTML (<settings-ui>)
    root_settings_html = """<!doctype html>
<html dir="$i18n{textdirection}" lang="$i18n{language}" class="loading">
<head>
  <meta charset="utf-8">
  <meta name="color-scheme" content="light dark">
  <title>Astra Settings</title>
  <base href="chrome://settings">
  <link rel="stylesheet" href="chrome://resources/css/md_colors.css">
  <style>
    html {
      overflow: hidden;
      touch-action: manipulation;
    }

    /* Astra Settings Theme on Root Level */
    :root, [dark], html, body {
      --md-background-color: #1a1a1d !important;
      --cr-toolbar-background-color: #1f1f22 !important;
      --cr-card-background-color: #26262a !important;
      --cr-card-border-radius: 18px !important;
      --cr-primary-text-color: #f4f4f6 !important;
      --cr-secondary-text-color: rgba(244, 244, 246, 0.68) !important;
      --cr-separator-color: rgba(255, 255, 255, 0.07) !important;
      --cr-separator-line: 1px solid rgba(255, 255, 255, 0.07) !important;
      --cr-focus-outline-color: rgba(255, 255, 255, 0.4) !important;
      --cr-checked-color: #ededf0 !important;
      --cr-hover-background-color: rgba(255, 255, 255, 0.04) !important;
      --cr-active-background-color: rgba(255, 255, 255, 0.075) !important;
      --cr-toggle-checked-bar-color: rgba(255, 255, 255, 0.2) !important;
      --cr-toggle-checked-button-color: #ededf0 !important;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Segoe UI", Roboto, sans-serif !important;
    }

    @media (prefers-color-scheme: dark) {
      html {
        background: #1a1a1d;
      }
    }

    html,
    body {
      height: 100%;
      margin: 0;
      background: #1a1a1d;
    }

    settings-ui {
      --settings-menu-width: 260px;
    }

    cr-toolbar {
      border-bottom: 1px solid rgba(255, 255, 255, 0.07) !important;
      background: #1f1f22 !important;
      -webkit-app-region: drag;
    }

    cr-toolbar #search, cr-toolbar cr-icon-button, cr-toolbar button, cr-toolbar input, cr-toolbar [role="button"], cr-toolbar a {
      -webkit-app-region: no-drag;
    }

    a.cr-nav-menu-item {
      border-radius: 12px !important;
      color: rgba(244, 244, 246, 0.68) !important;
      margin: 2px 8px !important;
      font-size: 13px !important;
      transition: background 0.15s ease, color 0.15s ease !important;
    }

    a.cr-nav-menu-item:hover {
      background: rgba(255, 255, 255, 0.04) !important;
      color: #f4f4f6 !important;
    }

    a.cr-nav-menu-item[selected],
    a.cr-nav-menu-item:focus {
      background: rgba(255, 255, 255, 0.075) !important;
      box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.06) !important;
      color: #f4f4f6 !important;
      font-weight: 500 !important;
    }

    a.cr-nav-menu-item[selected] cr-icon {
      color: #f4f4f6 !important;
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
    print("Restored Resource ID 25185 to native Chromium <settings-ui> root entry point")

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

    # Resource 25186: settings.js (Settings Menu, Basic Page, and <settings-tabs-page> Web Component)
    orig_settings = gzip.decompress(payloads[25186]).decode('utf-8')

    # Read Tabs Component code from src/settings/tabs_page.js
    tabs_page_path = '/Users/akshatmohanty/Astra/src/settings/tabs_page.js'
    with open(tabs_page_path, 'r', encoding='utf-8') as f:
        tabs_component_code = f.read()

    patched_settings = orig_settings

    # Remove unwanted menu items requested by user: "You and Google", "AI innovations", "System"
    people_menu = re.search(r'<a role="menuitem" id="people".*?</a>\s*', patched_settings, re.DOTALL)
    if people_menu:
        patched_settings = patched_settings.replace(people_menu.group(0), '')
        print("Removed 'You and Google' menu item from Settings sidebar")

    ai_menu = re.search(r'<a role="menuitem" href="/ai".*?</a>\s*', patched_settings, re.DOTALL)
    if ai_menu:
        patched_settings = patched_settings.replace(ai_menu.group(0), '')
        print("Removed 'AI innovations' menu item from Settings sidebar")

    system_menu = re.search(r'<a role="menuitem" id="system".*?</a>\s*', patched_settings, re.DOTALL)
    if system_menu:
        patched_settings = patched_settings.replace(system_menu.group(0), '')
        print("Removed 'System' menu item from Settings sidebar")

    # Also hide their basic page sections
    patched_settings = patched_settings.replace(
        '<template is="dom-if" if="[[showPage_(pageVisibility.people)]]" restamp>',
        '<template is="dom-if" if="[[false]]" restamp>'
    )
    patched_settings = patched_settings.replace(
        '<template is="dom-if" if="[[showAiPageAiFeatureSection_]]" restamp>',
        '<template is="dom-if" if="[[false]]" restamp>'
    )
    system_sec_pat = re.search(r'<settings-section page-title="\$i18n\{systemPageTitle\}" section="system">.*?</settings-section>', patched_settings, re.DOTALL)
    if system_sec_pat:
        patched_settings = patched_settings.replace(system_sec_pat.group(0), f'<template is="dom-if" if="[[false]]" restamp>{system_sec_pat.group(0)}</template>')
        print("Hidden 'System' section in basic page")

    patched_settings = patched_settings.replace(
        'TOP_LEVEL_EQUIVALENT_ROUTE=loadTimeData.getBoolean("isGuest")?guestTopLevelRoute:routes.PEOPLE;',
        'TOP_LEVEL_EQUIVALENT_ROUTE=loadTimeData.getBoolean("isGuest")?guestTopLevelRoute:routes.PRIVACY;'
    )

    # Style selected menu items with Astra's plate of light and 12px radius
    patched_settings = patched_settings.replace(
        '.cr-nav-menu-item[selected]{--iron-icon-fill-color:black;background:var(--google-blue-300);color:var(--google-grey-900)}',
        '.cr-nav-menu-item[selected]{--iron-icon-fill-color:#f4f4f6;background:rgba(255,255,255,0.075);box-shadow:inset 0 0 0 1px rgba(255,255,255,0.06);color:#f4f4f6;font-weight:500;border-radius:12px}'
    )

    # Inject Tabs menu item into getTemplate$4 (SettingsMenuElement)
    target_menu = '<a role="menuitem" id="appearance" href="/appearance" hidden="[[!pageVisibility.appearance]]" class="cr-nav-menu-item">'
    menu_item_html = """        <a role="menuitem" id="tabs" href="/tabs" class="cr-nav-menu-item">
          <cr-icon icon="settings20:auto-tab-group"></cr-icon>
          Tabs
          <cr-ripple></cr-ripple>
        </a>
"""
    patched_settings = patched_settings.replace(target_menu, menu_item_html + target_menu)

    # Inject Tabs section into getTemplate$6 (SettingsBasicPageElement)
    target_section = '<template is="dom-if" if="[[showPage_(pageVisibility.appearance)]]" restamp>'
    section_html = """        <settings-section page-title="Tabs" section="tabs">
          <settings-tabs-page prefs="{{prefs}}"></settings-tabs-page>
        </settings-section>
"""
    patched_settings = patched_settings.replace(target_section, section_html + target_section)

    # Append Tabs custom element definition before exports
    export_idx = patched_settings.rfind('export{')
    if export_idx != -1:
        patched_settings = (
            patched_settings[:export_idx]
            + '\n' + tabs_component_code + '\n'
            + patched_settings[export_idx:]
        )
        payloads[25186] = gzip.compress(patched_settings.encode('utf-8'))
        print("Patched Resource ID 25186 (settings.js): Injected native Tabs menu item, section, and <settings-tabs-page>")
    else:
        print("Warning: export statement not found in Resource 25186")

    # Icons in resources.pak
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
