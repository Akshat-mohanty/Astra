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

    # 2. Build complete self-contained HTML (using external module new_tab_page.js for 100% CSP compliance)
    html_content = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>&#8203;</title>
  <link rel="icon" type="image/png" href="{favicon_uri}">
  <link rel="shortcut icon" type="image/png" href="{favicon_uri}">
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
      padding: 0 16px;
      background: #191919;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
      position: fixed;
      top: 0;
      left: 0;
      z-index: 100;
      -webkit-app-region: drag;
    }}

    /* Never show duplicate top bar if window is a standard browser window with native toolbar */
    @media (display-mode: browser) {{
      .top-nav-bar {{
        display: none !important;
      }}
      body {{
        padding-top: 24px !important;
      }}
    }}

    .nav-controls {{
      display: flex;
      align-items: center;
      gap: 14px;
      -webkit-app-region: no-drag;
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

    /* Pinned / Recent Tabs Strip matching Dia */
    .pinned-tabs-strip {{
      display: flex;
      align-items: center;
      gap: 4px;
      margin-left: 14px;
      padding-left: 14px;
      border-left: 1px solid rgba(255, 255, 255, 0.07);
      -webkit-app-region: no-drag;
      overflow-x: auto;
      scrollbar-width: none;
    }}

    .tab-pill {{
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 4px 10px;
      border-radius: 7px;
      font-size: 12.5px;
      font-weight: 450;
      color: #a8a8ac;
      background: transparent;
      border: none;
      cursor: pointer;
      white-space: nowrap;
      text-decoration: none;
      transition: background 0.15s ease, color 0.15s ease;
      max-width: 170px;
    }}

    .tab-pill:hover {{
      background: rgba(255, 255, 255, 0.08);
      color: #ffffff;
    }}

    .tab-favicon {{
      width: 14px;
      height: 14px;
      border-radius: 3px;
      object-fit: contain;
      flex-shrink: 0;
    }}

    .tab-title {{
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }}

    main {{
      width: 100%;
      max-width: 650px;
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
      background: #2d2d2e;
      border-radius: 22px;
      padding: 16px 20px 14px 20px;
      display: flex;
      flex-direction: column;
      gap: 12px;
      box-shadow: 0 16px 44px rgba(0, 0, 0, 0.45);
      border: 1px solid rgba(255, 255, 255, 0.07);
      transition: box-shadow 0.2s ease, border-color 0.2s ease, background 0.2s ease;
    }}

    .prompt-card:focus-within {{
      background: #2e2e30;
      border-color: rgba(255, 255, 255, 0.12);
      box-shadow: 0 20px 52px rgba(0, 0, 0, 0.55);
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

    #file-input {{
      display: none;
    }}

    .corner-settings-btn {{
      position: fixed;
      top: 18px;
      right: 20px;
      width: 36px;
      height: 36px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #88888b;
      background: transparent;
      border: 1px solid transparent;
      text-decoration: none;
      transition: all 0.15s ease;
      z-index: 90;
      -webkit-app-region: no-drag;
    }}

    .corner-settings-btn:hover {{
      color: #f4f3ef;
      background: rgba(255, 255, 255, 0.08);
      border-color: rgba(255, 255, 255, 0.08);
    }}
  </style>
</head>
<body>
  <!-- Corner Settings Action Button -->
  <a href="chrome://settings" class="corner-settings-btn" title="Astra Settings (⌘,)">
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="3"></circle>
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
    </svg>
  </a>
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

    <!-- Pinned / Recent Tabs Strip matching Dia -->
    <div class="pinned-tabs-strip" id="pinned-tabs-strip">
      <a class="tab-pill" href="https://github.com/Akshat-mohanty/Astra" title="GitHub — Astra">
        <svg class="tab-favicon" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/>
        </svg>
        <span class="tab-title">GitHub — Astra</span>
      </a>

      <a class="tab-pill" href="https://google.com" title="Google">
        <svg class="tab-favicon" viewBox="0 0 24 24">
          <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
          <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
          <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
          <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
        </svg>
        <span class="tab-title">Google</span>
      </a>

      <a class="tab-pill" href="https://claude.ai" title="Claude">
        <svg class="tab-favicon" viewBox="0 0 24 24" fill="#D97706">
          <circle cx="12" cy="12" r="10"/>
        </svg>
        <span class="tab-title">Claude</span>
      </a>
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

  // Prevent duplicate bar if opened in a window that already has native toolbar
  try {
    if (window.matchMedia && window.matchMedia('(display-mode: browser)').matches) {
      const topBar = document.querySelector('.top-nav-bar');
      if (topBar) topBar.style.display = 'none';
      document.body.style.paddingTop = '24px';
    }
  } catch (err) {}

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
    const updateSubmitState = () => {
      const hasText = input.value.trim().length > 0;
      if (hasText) {
        submitBtn.classList.add('active');
        submitBtn.style.background = '#ffffff';
        submitBtn.style.color = '#191919';
      } else {
        submitBtn.classList.remove('active');
        submitBtn.style.background = '#3e3f41';
        submitBtn.style.color = '#88888b';
      }
    };
    input.addEventListener('input', updateSubmitState);
    input.addEventListener('change', updateSubmitState);
  }

  if (searchForm) {
    searchForm.addEventListener('submit', (e) => {
      e.preventDefault();
      if (!input) return;
      const query = input.value.trim();
      if (!query) return;

      const lower = query.toLowerCase();
      if (lower === 'settings' || lower === 'preferences' || lower === 'astra://settings') {
        window.location.href = 'chrome://settings';
        return;
      }

      const isUrl = /^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$/.test(query)
                 || query.startsWith('localhost')
                 || query.includes('://');

      if (isUrl) {
        const dest = (query.startsWith('http://') || query.startsWith('https://') || query.startsWith('chrome://'))
                     ? query : 'https://' + query;
        window.location.href = dest;
      } else {
        window.location.href = 'https://www.google.com/search?q=' + encodeURIComponent(query);
      }
    });
  }

  // Keyboard shortcut Cmd+, for Settings
  window.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === ',') {
      e.preventDefault();
      window.location.href = 'chrome://settings';
    }
  });

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
