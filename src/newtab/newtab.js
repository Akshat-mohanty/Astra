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
      try {
        let saved = {};
        try {
          const raw = localStorage.getItem('astra_settings');
          if (raw) saved = JSON.parse(raw);
        } catch(e) {}
        const currentCollapsed = !!saved.sidebar_collapsed;
        const nextCollapsed = !currentCollapsed;
        saved.sidebar_collapsed = nextCollapsed;
        saved.vtab_width = 'expanded';
        localStorage.setItem('astra_settings', JSON.stringify(saved));
        const payload = encodeURIComponent(JSON.stringify(saved));
        const url = 'http://127.0.0.1:4545/api/setting?key=sidebar_collapsed&val=' + encodeURIComponent(nextCollapsed ? '1' : '0') + '&json=' + payload + '&t=' + Date.now();
        fetch(url, { mode: 'no-cors' }).catch(() => {});
        new Image().src = url;
      } catch(err) {}
    });
  }

  // Active state for submit button when input has text (matching Dia's active white arrow)
  if (input && submitBtn) {
    const updateSubmitState = () => {
      const hasText = input.value.trim().length > 0;
      if (hasText) {
        submitBtn.classList.add('active');
      } else {
        submitBtn.classList.remove('active');
      }
    };
    input.addEventListener('input', updateSubmitState);
    input.addEventListener('change', updateSubmitState);
  }

  // Execute Search or Navigate
  if (searchForm) {
    searchForm.addEventListener('submit', (e) => {
      e.preventDefault();
      if (!input) return;
      const query = input.value.trim();
      if (!query) return;

      const lower = query.toLowerCase();
      if (lower === 'settings' || lower === 'preferences' || lower === 'astra://settings') {
        window.open('chrome://settings', '_blank');
        return;
      }

      const isUrl = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/.test(query)
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

  // Keyboard shortcut Cmd+, for Settings (opens in a new tab)
  window.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === ',') {
      e.preventDefault();
      window.open('chrome://settings', '_blank');
    }
  });

  // Vertical tabs footer Settings button (opens in a separate new tab)
  const vtabFooterBtn = document.querySelector('.vtab-footer-btn');
  if (vtabFooterBtn) {
    vtabFooterBtn.addEventListener('click', (e) => {
      e.preventDefault();
      window.open('chrome://settings#tabs', '_blank');
    });
  }

  // Add tabs or files (opens file picker or attaches tab reference)
  if (addBtn && fileInput) {
    addBtn.addEventListener('click', () => {
      fileInput.click();
    });

    fileInput.addEventListener('change', () => {
      if (fileInput.files.length > 0) {
        const fileNames = Array.from(fileInput.files).map(f => f.name).join(', ');
        if (input) {
          input.value = `[Attached: ${fileNames}] `;
          input.focus();
          if (submitBtn) submitBtn.classList.add('active');
        }
      }
    });
  }

  // Voice Input (Web Speech API)
  if (micBtn && input) {
    micBtn.addEventListener('click', () => {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (SpeechRecognition) {
        const recognition = new SpeechRecognition();
        recognition.lang = 'en-US';
        recognition.start();
        micBtn.style.color = '#ef4444'; // Red recording indicator

        recognition.onresult = (event) => {
          const transcript = event.results[0][0].transcript;
          input.value = transcript;
          micBtn.style.color = '#78787a';
          if (submitBtn) submitBtn.classList.add('active');
          input.focus();
        };

        recognition.onerror = () => {
          micBtn.style.color = '#78787a';
        };

        recognition.onend = () => {
          micBtn.style.color = '#78787a';
        };
      } else {
        input.placeholder = "Voice listening not supported on this engine";
        setTimeout(() => {
          input.placeholder = "Ask anything...";
        }, 2000);
      }
    });
  }

  // Tab Orientation and Vertical Sidebar Controller
  const vtabSidebar = document.getElementById('astra-vtab-sidebar');
  const vtabToggleBtn = document.getElementById('vtab-toggle-btn');
  const vtabNewBtn = document.getElementById('vtab-new-btn');

  function applySettings() {
    let settings = {};
    try {
      const saved = localStorage.getItem('astra_settings');
      if (saved) settings = JSON.parse(saved);
    } catch (e) {}

    const orientation = settings.tab_orientation || 'horizontal';
    const isVertical = (orientation === 'vertical');
    const isCompact = (settings.vtab_width === 'compact');

    document.body.classList.toggle('tabs-vertical', isVertical);
    document.body.classList.toggle('tabs-horizontal', !isVertical);
    document.body.classList.toggle('vtab-compact', isCompact);

    if (settings.accent) {
      document.documentElement.style.setProperty('--accent-color', settings.accent);
    }
  }

  // Initial apply
  applySettings();

  // Listen for storage changes across tabs / settings page
  window.addEventListener('storage', (e) => {
    if (e.key === 'astra_settings') {
      applySettings();
    }
  });

  window.addEventListener('astra-settings-updated', () => {
    applySettings();
  });

  // Toggle compact vertical tabs sidebar
  if (vtabToggleBtn) {
    vtabToggleBtn.addEventListener('click', () => {
      const isCompact = document.body.classList.toggle('vtab-compact');
      try {
        const saved = localStorage.getItem('astra_settings');
        const settings = saved ? JSON.parse(saved) : {};
        settings.vtab_width = isCompact ? 'compact' : 'expanded';
        localStorage.setItem('astra_settings', JSON.stringify(settings));
        window.dispatchEvent(new CustomEvent('astra-settings-updated', { detail: settings }));

        const payload = encodeURIComponent(JSON.stringify(settings));
        const url = 'http://127.0.0.1:4545/api/setting?key=vtab_width&val=' + encodeURIComponent(isCompact ? 'compact' : 'expanded') + '&json=' + payload + '&t=' + Date.now();
        fetch(url, { mode: 'no-cors' }).catch(() => {});
        new Image().src = url;
      } catch (e) {}
    });
  }

  // New Tab button in vertical sidebar
  if (vtabNewBtn) {
    vtabNewBtn.addEventListener('click', () => {
      window.open('chrome://newtab', '_blank');
    });
  }

  // Handle closing tabs inside vertical sidebar
  if (vtabSidebar) {
    vtabSidebar.addEventListener('click', (e) => {
      const closeBtn = e.target.closest('.vtab-close-btn');
      if (closeBtn) {
        e.preventDefault();
        e.stopPropagation();
        const item = closeBtn.closest('.vtab-item');
        if (item) {
          item.style.opacity = '0';
          item.style.transform = 'translateX(-12px)';
          setTimeout(() => item.remove(), 160);
        }
      }
    });
  }

  // Keyboard shortcut: pressing / or Cmd+K focuses prompt
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
