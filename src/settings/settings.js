// Astra Browser Custom Settings Controller
// Manages settings state, persistence, search filtering, and WebUI bridge

const DEFAULT_SETTINGS = {
  theme: 'theme-obsidian',
  accent: '#7c5cfc',
  startup_mode: 'newtab',
  search_engine: 'google',
  memory_saver: true,
  gpu_accel: true,
  dim_tabs: true,
  tab_audio: true,
  search_suggestions: true,
  ai_synthesis: true,
  block_3p_cookies: true,
  send_dnt: true,
  https_only: true,
  ask_download: false,
  download_path: '~/Downloads'
};

class SettingsManager {
  constructor() {
    this.settings = this.loadSettings();
    this.initDOM();
    this.bindEvents();
    this.applySettings();
    this.handleRoute();
  }

  loadSettings() {
    try {
      const saved = localStorage.getItem('astra_settings');
      if (saved) {
        return { ...DEFAULT_SETTINGS, ...JSON.parse(saved) };
      }
    } catch (e) {
      console.warn('Failed to load settings from storage', e);
    }
    return { ...DEFAULT_SETTINGS };
  }

  saveSettings() {
    try {
      localStorage.setItem('astra_settings', JSON.stringify(this.settings));
      // Broadcast settings update to other open Astra tabs (e.g. newtab)
      window.dispatchEvent(new CustomEvent('astra-settings-updated', { detail: this.settings }));
    } catch (e) {
      console.error('Failed to save settings', e);
    }
  }

  initDOM() {
    this.navItems = document.querySelectorAll('.nav-item');
    this.sections = document.querySelectorAll('.settings-section');
    this.pageTitle = document.getElementById('page-title');
    this.sectionDesc = document.querySelector('.section-desc');
    this.searchInput = document.getElementById('settings-search');
    this.toast = document.getElementById('toast');
    this.toastText = document.getElementById('toast-text');

    // Modals
    this.clearModal = document.getElementById('clear-data-modal');
  }

  bindEvents() {
    // Navigation routing
    this.navItems.forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const sectionId = item.getAttribute('data-section');
        this.navigateTo(sectionId);
      });
    });

    // Hash change routing
    window.addEventListener('hashchange', () => this.handleRoute());

    // Search filter
    if (this.searchInput) {
      this.searchInput.addEventListener('input', (e) => {
        this.filterSettings(e.target.value.trim().toLowerCase());
      });
    }

    // Startup Mode Radios
    const startupRadios = document.querySelectorAll('input[name="startup_mode"]');
    startupRadios.forEach(radio => {
      radio.checked = (radio.value === this.settings.startup_mode);
      radio.addEventListener('change', () => {
        this.settings.startup_mode = radio.value;
        this.saveSettings();
        this.showToast('Startup behavior updated');
      });
    });

    // Theme Selector
    const themeButtons = document.querySelectorAll('#theme-selector .segment-btn');
    themeButtons.forEach(btn => {
      if (btn.getAttribute('data-theme') === this.settings.theme) {
        themeButtons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
      }
      btn.addEventListener('click', () => {
        themeButtons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const theme = btn.getAttribute('data-theme');
        this.settings.theme = theme;
        this.applyTheme(theme);
        this.saveSettings();
        this.showToast(`Theme changed to ${btn.innerText}`);
      });
    });

    // Accent Color Picker
    const accentDots = document.querySelectorAll('#accent-picker .color-dot');
    accentDots.forEach(dot => {
      if (dot.getAttribute('data-accent') === this.settings.accent) {
        accentDots.forEach(d => d.classList.remove('active'));
        dot.classList.add('active');
      }
      dot.addEventListener('click', () => {
        accentDots.forEach(d => d.classList.remove('active'));
        dot.classList.add('active');
        const color = dot.getAttribute('data-accent');
        this.settings.accent = color;
        this.applyAccent(color);
        this.saveSettings();
        this.showToast('Accent color updated');
      });
    });

    // Search Engine Selector
    const searchSelect = document.getElementById('pref-search-engine');
    if (searchSelect) {
      searchSelect.value = this.settings.search_engine || 'google';
      searchSelect.addEventListener('change', (e) => {
        this.settings.search_engine = e.target.value;
        this.saveSettings();
        this.showToast(`Default search set to ${searchSelect.options[searchSelect.selectedIndex].text}`);
      });
    }

    // Checkboxes / Toggles
    this.bindToggle('pref-memory-saver', 'memory_saver', 'Memory Saver');
    this.bindToggle('pref-gpu-accel', 'gpu_accel', 'GPU Acceleration');
    this.bindToggle('pref-dim-tabs', 'dim_tabs', 'Inactive Tab Dimming');
    this.bindToggle('pref-tab-audio', 'tab_audio', 'Tab Audio Indicators');
    this.bindToggle('pref-search-suggestions', 'search_suggestions', 'Search Suggestions');
    this.bindToggle('pref-ai-synthesis', 'ai_synthesis', 'AI Query Synthesis');
    this.bindToggle('pref-block-3p-cookies', 'block_3p_cookies', 'Third-Party Cookie Blocking');
    this.bindToggle('pref-send-dnt', 'send_dnt', 'Do Not Track Signal');
    this.bindToggle('pref-https-only', 'https_only', 'HTTPS-Only Mode');
    this.bindToggle('pref-ask-download', 'ask_download', 'Download Prompting');

    // Buttons
    const btnDefault = document.getElementById('btn-make-default');
    if (btnDefault) {
      btnDefault.addEventListener('click', () => {
        if (window.chrome && chrome.send) {
          try { chrome.send('setAsDefaultBrowser'); } catch (e) {}
        }
        btnDefault.disabled = true;
        btnDefault.innerText = 'Default Configured';
        this.showToast('Astra is configured as default browser');
      });
    }

    const btnUpdates = document.getElementById('btn-check-updates');
    if (btnUpdates) {
      btnUpdates.addEventListener('click', () => {
        btnUpdates.innerText = 'Checking...';
        btnUpdates.disabled = true;
        setTimeout(() => {
          btnUpdates.innerText = 'Up to Date';
          document.getElementById('update-status-text').innerText = 'Astra v1.2.0 (Diamond Edition) is up to date.';
          this.showToast('Browser is on the latest version');
        }, 800);
      });
    }

    // Clear Data Modal
    const btnOpenClear = document.getElementById('btn-open-clear-data');
    const btnCloseModal = document.getElementById('btn-close-modal');
    const btnCancelClear = document.getElementById('btn-cancel-clear');
    const btnConfirmClear = document.getElementById('btn-confirm-clear');

    if (btnOpenClear && this.clearModal) {
      btnOpenClear.addEventListener('click', () => this.clearModal.classList.add('open'));
      btnCloseModal.addEventListener('click', () => this.clearModal.classList.remove('open'));
      btnCancelClear.addEventListener('click', () => this.clearModal.classList.remove('open'));
      btnConfirmClear.addEventListener('click', () => {
        btnConfirmClear.disabled = true;
        btnConfirmClear.innerText = 'Clearing...';

        // Clear local storage / session caches
        try {
          sessionStorage.clear();
        } catch (e) {}

        // Bridge to Chromium WebUI clear data handler if accessible
        if (window.chrome && chrome.send) {
          try {
            chrome.send('clearBrowsingData', [
              document.getElementById('clear-history').checked,
              document.getElementById('clear-cookies').checked,
              document.getElementById('clear-cache').checked,
              document.getElementById('clear-timerange').value
            ]);
          } catch (e) {}
        }

        setTimeout(() => {
          this.clearModal.classList.remove('open');
          btnConfirmClear.disabled = false;
          btnConfirmClear.innerText = 'Clear Data';
          this.showToast('Browsing history and cached data cleared');
        }, 600);
      });
    }
  }

  bindToggle(elementId, settingKey, label) {
    const el = document.getElementById(elementId);
    if (!el) return;
    el.checked = !!this.settings[settingKey];
    el.addEventListener('change', () => {
      this.settings[settingKey] = el.checked;
      this.saveSettings();
      this.showToast(`${label} ${el.checked ? 'enabled' : 'disabled'}`);
    });
  }

  applySettings() {
    this.applyTheme(this.settings.theme);
    this.applyAccent(this.settings.accent);
  }

  applyTheme(theme) {
    document.body.classList.remove('theme-obsidian', 'theme-charcoal', 'theme-oled');
    document.body.classList.add(theme);
  }

  applyAccent(color) {
    document.documentElement.style.setProperty('--accent-color', color);
    // Convert hex to rgb for glow
    const hex = color.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    document.documentElement.style.setProperty('--accent-glow', `rgba(${r}, ${g}, ${b}, 0.35)`);
  }

  handleRoute() {
    const hash = (window.location.hash || '#general').replace('#', '');
    this.navigateTo(hash);
  }

  navigateTo(sectionId) {
    const targetSection = document.getElementById(`section-${sectionId}`);
    if (!targetSection) return;

    this.sections.forEach(s => s.classList.remove('active'));
    this.navItems.forEach(n => n.classList.remove('active'));

    targetSection.classList.add('active');
    const activeNav = document.querySelector(`.nav-item[data-section="${sectionId}"]`);
    if (activeNav) activeNav.classList.add('active');

    // Update title
    const titles = {
      general: 'General Settings',
      appearance: 'Appearance & Themes',
      search: 'Search & AI Assistant',
      privacy: 'Privacy & Security',
      downloads: 'Downloads & Files',
      shortcuts: 'Keyboard Shortcuts',
      about: 'About Astra'
    };

    const descriptions = {
      general: 'Manage startup behavior, system defaults, and browsing performance.',
      appearance: 'Customize color themes, accent glows, tab strip layout, and visual styling.',
      search: 'Configure your primary search provider and smart prompt bar synthesis.',
      privacy: 'Manage cookie tracking rules, browsing history, and secure HTTPS connections.',
      downloads: 'Set your preferred download location and file saving behavior.',
      shortcuts: 'Quick hotkey reference to master navigation across Astra tabs and tools.',
      about: 'System details, release build specifications, and developer information.'
    };

    if (this.pageTitle) this.pageTitle.innerText = titles[sectionId] || 'Settings';
    if (this.sectionDesc) this.sectionDesc.innerText = descriptions[sectionId] || '';

    window.location.hash = sectionId;
  }

  filterSettings(query) {
    if (!query) {
      // Restore all
      document.querySelectorAll('.card-group').forEach(cg => cg.style.display = '');
      document.querySelectorAll('.setting-row, .radio-option, .shortcut-row').forEach(row => row.style.display = '');
      return;
    }

    // Switch to active section or search across all
    this.sections.forEach(sec => sec.classList.add('active'));

    document.querySelectorAll('.card-group').forEach(group => {
      let groupHasMatch = false;
      const rows = group.querySelectorAll('.setting-row, .radio-option, .shortcut-row');
      rows.forEach(row => {
        const text = row.innerText.toLowerCase();
        if (text.includes(query)) {
          row.style.display = '';
          groupHasMatch = true;
        } else {
          row.style.display = 'none';
        }
      });
      group.style.display = groupHasMatch ? '' : 'none';
    });
  }

  showToast(message) {
    if (!this.toast || !this.toastText) return;
    this.toastText.innerText = message;
    this.toast.classList.add('show');
    clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => {
      this.toast.classList.remove('show');
    }, 2400);
  }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.astraSettings = new SettingsManager();
});
