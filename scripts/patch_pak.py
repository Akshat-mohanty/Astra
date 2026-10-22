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

    # 1. Read base64 logo
    logo_path = '/Users/akshatmohanty/Astra/src/newtab/astra_logo.png'
    with open(logo_path, 'rb') as f:
        logo_b64 = base64.b64encode(f.read()).decode('utf-8')
    data_uri = f"data:image/png;base64,{logo_b64}"

    # 2. Build complete self-contained HTML (using external module new_tab_page.js for 100% CSP compliance)
    html_content = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>New Tab</title>
  <style>
    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", Roboto, sans-serif;
      -webkit-font-smoothing: antialiased;
    }}

    ::selection {{
      background: rgba(255, 255, 255, 0.2);
      color: #ffffff;
    }}

    body {{
      background-color: #181819;
      color: #f5f5f5;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      align-items: center;
      padding: 56px 24px 20px 24px;
      overflow: hidden;
      user-select: none;
    }}

    /* Top Navigation Bar matching Dia / Arc style (Screenshot 2026-10-23 at 12.48.33 AM) */
    .top-nav-bar {{
      width: 100%;
      height: 44px;
      display: flex;
      align-items: center;
      justify-content: flex-start;
      padding: 0 18px;
      background: #181819;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      position: fixed;
      top: 0;
      left: 0;
      z-index: 100;
    }}

    .nav-controls {{
      display: flex;
      align-items: center;
      gap: 14px;
    }}

    .nav-icon-btn {{
      background: transparent;
      border: none;
      color: #8c8c8e;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      padding: 6px;
      border-radius: 6px;
      transition: color 0.15s ease, background 0.15s ease;
    }}

    .nav-icon-btn:hover {{
      color: #ffffff;
      background: rgba(255, 255, 255, 0.08);
    }}

    .nav-icon-btn:active {{
      transform: scale(0.95);
    }}

    main {{
      width: 100%;
      max-width: 652px;
      display: flex;
      flex-direction: column;
      align-items: center;
      margin: auto 0;
    }}

    .emblem-container {{
      margin-bottom: 28px;
      display: flex;
      align-items: center;
      justify-content: center;
    }}

    .emblem-img {{
      width: 80px;
      height: 90px;
      object-fit: contain;
      pointer-events: none;
      user-select: none;
      opacity: 0.95;
      transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.25s ease;
    }}

    .emblem-container:hover .emblem-img {{
      transform: scale(1.06);
      opacity: 1;
    }}

    .prompt-card {{
      width: 100%;
      background: #2d2d2d;
      border-radius: 20px;
      padding: 16px 18px 14px 18px;
      display: flex;
      flex-direction: column;
      gap: 14px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
      border: 1px solid rgba(255, 255, 255, 0.04);
      transition: box-shadow 0.2s ease, border-color 0.2s ease, background 0.2s ease;
    }}

    .prompt-card:focus-within {{
      background: #2f2f2f;
      border-color: rgba(255, 255, 255, 0.1);
      box-shadow: 0 12px 40px rgba(0, 0, 0, 0.35);
    }}

    .input-row {{
      display: flex;
      align-items: center;
      gap: 12px;
      width: 100%;
    }}

    .search-icon {{
      color: #7a7a7a;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }}

    .prompt-input {{
      flex: 1;
      background: transparent;
      border: none;
      outline: none;
      font-size: 17px;
      color: #f5f5f5;
      font-weight: 400;
      letter-spacing: -0.015em;
      caret-color: #ffffff;
      user-select: text;
    }}

    .prompt-input::placeholder {{
      color: #787878;
      font-weight: 400;
    }}

    .controls-row {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      padding-top: 2px;
    }}

    .add-btn {{
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #383838;
      color: #a3a3a3;
      border: none;
      border-radius: 9999px;
      padding: 6px 14px;
      font-size: 13px;
      font-weight: 450;
      cursor: pointer;
      transition: background 0.15s ease, color 0.15s ease;
    }}

    .add-btn:hover {{
      background: #424242;
      color: #d1d1d1;
    }}

    .right-actions {{
      display: flex;
      align-items: center;
      gap: 10px;
    }}

    .action-icon-btn {{
      background: transparent;
      border: none;
      color: #787878;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      padding: 6px;
      border-radius: 50%;
      transition: color 0.15s ease, background 0.15s ease;
    }}

    .action-icon-btn:hover {{
      color: #b0b0b0;
    }}

    .submit-arrow-btn {{
      width: 30px;
      height: 30px;
      background: #383838;
      color: #787878;
      border: none;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: background 0.15s ease, color 0.15s ease, transform 0.1s ease;
    }}

    .submit-arrow-btn:hover {{
      background: #484848;
      color: #ffffff;
    }}

    .bottom-indicator {{
      width: 42px;
      height: 5px;
      border-radius: 9999px;
      border: 1px solid #383839;
      background: transparent;
      margin-bottom: 2px;
    }}

    #file-input {{
      display: none;
    }}
  </style>
</head>
<body>
  <!-- Top Navigation Bar matching Dia / Arc style (Screenshot 2026-10-23 at 12.48.33 AM) -->
  <header class="top-nav-bar">
    <div class="nav-controls">
      <button type="button" class="nav-icon-btn" id="sidebar-toggle-btn" aria-label="Toggle Sidebar" title="Toggle Sidebar">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect width="18" height="18" x="3" y="3" rx="4"></rect>
          <path d="M9 3v18"></path>
          <path d="M6 7h1"></path>
          <path d="M6 11h1"></path>
          <path d="M6 15h1"></path>
        </svg>
      </button>

      <button type="button" class="nav-icon-btn" id="nav-back-btn" aria-label="Back" title="Back">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
      </button>

      <button type="button" class="nav-icon-btn" id="nav-forward-btn" aria-label="Forward" title="Forward">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
      </button>

      <button type="button" class="nav-icon-btn" id="nav-reload-btn" aria-label="Reload" title="Reload">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.85.83 6.72 2.24"></path>
          <polyline points="21 3 21 8 16 8"></polyline>
        </svg>
      </button>
    </div>
  </header>

  <main>
    <div class="emblem-container">
      <img src="{data_uri}" alt="Astra" class="emblem-img" />
    </div>

    <form class="prompt-card" id="search-form">
      <div class="input-row">
        <span class="search-icon">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
        </span>
        <input 
          type="text" 
          id="search-input" 
          class="prompt-input" 
          placeholder="Ask anything..." 
          autofocus 
          autocomplete="off" 
          spellcheck="false"
        />
      </div>

      <div class="controls-row">
        <button type="button" class="add-btn" id="add-btn">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
          <span>Add tabs or files</span>
        </button>

        <div class="right-actions">
          <button type="button" class="action-icon-btn" id="mic-btn" aria-label="Voice input">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"></path>
              <path d="M19 10v2a7 7 0 0 1-14 0v-2"></path>
              <line x1="12" y1="19" x2="12" y2="23"></line>
              <line x1="8" y1="23" x2="16" y2="23"></line>
            </svg>
          </button>

          <button type="submit" class="submit-arrow-btn" aria-label="Submit">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <line x1="12" y1="19" x2="12" y2="5"></line>
              <polyline points="5 12 12 5 19 12"></polyline>
            </svg>
          </button>
        </div>
      </div>
    </form>

    <input type="file" id="file-input" multiple />
  </main>

  <div class="bottom-indicator"></div>

  <!-- Loaded as standard WebUI script satisfying CSP -->
  <script type="module" src="new_tab_page.js"></script>
</body>
</html>
"""

    js_content = """
document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('search-input');
  const searchForm = document.getElementById('search-form');
  const addBtn = document.getElementById('add-btn');
  const fileInput = document.getElementById('file-input');
  const micBtn = document.getElementById('mic-btn');
  const submitBtn = searchForm ? searchForm.querySelector('.submit-arrow-btn') : null;

  // Top navigation bar controls
  const backBtn = document.getElementById('nav-back-btn');
  const forwardBtn = document.getElementById('nav-forward-btn');
  const reloadBtn = document.getElementById('nav-reload-btn');
  const sidebarBtn = document.getElementById('sidebar-toggle-btn');

  if (backBtn) backBtn.addEventListener('click', () => window.history.back());
  if (forwardBtn) forwardBtn.addEventListener('click', () => window.history.forward());
  if (reloadBtn) reloadBtn.addEventListener('click', () => window.location.reload());
  if (sidebarBtn) {
    sidebarBtn.addEventListener('click', () => {
      if (input) {
        input.focus();
        input.select();
      }
    });
  }

  if (input && submitBtn) {
    input.addEventListener('input', () => {
      const hasText = input.value.trim().length > 0;
      submitBtn.style.color = hasText ? '#ffffff' : '#787878';
      submitBtn.style.background = hasText ? '#4a4a4a' : '#383838';
    });
  }

  if (searchForm) {
    searchForm.addEventListener('submit', (e) => {
      e.preventDefault();
      if (!input) return;
      const query = input.value.trim();
      if (!query) return;

      const isUrl = /^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$/.test(query)
                 || query.startsWith('localhost')
                 || query.includes('://');

      if (isUrl) {
        const dest = query.startsWith('http://') || query.startsWith('https://') ? query : 'https://' + query;
        window.location.href = dest;
      } else {
        window.location.href = 'https://www.google.com/search?q=' + encodeURIComponent(query);
      }
    });
  }

  if (addBtn && fileInput) {
    addBtn.addEventListener('click', () => fileInput.click());
    fileInput.addEventListener('change', () => {
      if (fileInput.files.length > 0) {
        const fileNames = Array.from(fileInput.files).map(f => f.name).join(', ');
        if (input) {
          input.value = `[Attached: ${fileNames}] `;
          input.focus();
        }
      }
    });
  }

  if (micBtn && input) {
    micBtn.addEventListener('click', () => {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (SpeechRecognition) {
        const recognition = new SpeechRecognition();
        recognition.lang = 'en-US';
        recognition.start();
        micBtn.style.color = '#ef4444';
        recognition.onresult = (event) => {
          input.value = event.results[0][0].transcript;
          micBtn.style.color = '#787878';
          input.focus();
        };
        recognition.onerror = () => micBtn.style.color = '#787878';
        recognition.onend = () => micBtn.style.color = '#787878';
      }
    });
  }

  window.addEventListener('keydown', (e) => {
    if ((e.key === '/' || (e.metaKey && e.key === 'k')) && document.activeElement !== input) {
      e.preventDefault();
      if (input) {
        input.focus();
        input.select();
      }
    }
  });
});
"""

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

    # Replace Resource ID 23390 (HTML) and 23392 (JS)
    payloads[23390] = compressed_html
    payloads[23392] = compressed_js
    print("Replaced Resource ID 23390 (HTML) and 23392 (JS) with CSP compliance")

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
