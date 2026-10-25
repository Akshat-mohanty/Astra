// Astra Settings - Completely Redesigned UI
// Clean, modern settings interface inspired by Arc/Zen

function getTemplateNewSettings() {
  return html$1`<!--_html_template_start_-->
    <style include="cr-shared-style settings-shared">
      :host {
        display: block;
        padding: 0 0 48px 0;
        position: relative;
        min-height: 100%;
        background: #0a0a0a;
      }

      .settings-container {
        max-width: 880px;
        margin: 0 auto;
        padding: 32px 24px 0 24px;
      }

      .settings-header {
        margin-bottom: 40px;
        padding-bottom: 24px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.06);
      }

      .settings-title {
        font-size: 28px;
        font-weight: 600;
        letter-spacing: -0.5px;
        color: #ffffff;
        margin-bottom: 8px;
        display: flex;
        align-items: center;
        gap: 12px;
      }

      .settings-subtitle {
        font-size: 14px;
        color: #9b9b9b;
        line-height: 1.6;
      }

      .search-section {
        margin-bottom: 32px;
      }

      .search-box {
        display: flex;
        align-items: center;
        gap: 10px;
        background: #151515;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 12px;
        padding: 10px 16px;
        transition: border-color 0.2s ease, background 0.2s ease;
      }

      .search-box:hover {
        border-color: rgba(255, 255, 255, 0.15);
      }

      .search-box:focus-within {
        border-color: rgba(255, 255, 255, 0.3);
        background: #1a1a1a;
      }

      .search-icon {
        color: #6b6b6b;
        flex-shrink: 0;
      }

      .search-input {
        flex: 1;
        background: transparent;
        border: none;
        outline: none;
        color: #ffffff;
        font-size: 14px;
        font-family: inherit;
      }

      .search-input::placeholder {
        color: #6b6b6b;
      }

      .nav-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 12px;
        margin-bottom: 40px;
      }

      .nav-card {
        background: #151515;
        border: 1px solid rgba(255, 255, 255, 0.06);
        border-radius: 12px;
        padding: 16px;
        cursor: pointer;
        transition: all 0.2s ease;
        display: flex;
        align-items: flex-start;
        gap: 14px;
      }

      .nav-card:hover {
        background: #1a1a1a;
        border-color: rgba(255, 255, 255, 0.12);
        transform: translateY(-1px);
      }

      .nav-card:active {
        transform: translateY(0);
      }

      .nav-icon {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        background: rgba(255, 255, 255, 0.06);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        color: #ffffff;
      }

      .nav-content {
        flex: 1;
        min-width: 0;
      }

      .nav-title {
        font-size: 14px;
        font-weight: 600;
        color: #ffffff;
        margin-bottom: 4px;
      }

      .nav-desc {
        font-size: 12px;
        color: #9b9b9b;
        line-height: 1.4;
      }

      .section {
        margin-bottom: 32px;
      }

      .section-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 16px;
        padding: 0 4px;
      }

      .section-title-group {
        display: flex;
        align-items: center;
        gap: 10px;
      }

      .section-title {
        font-size: 16px;
        font-weight: 600;
        color: #ffffff;
      }

      .section-desc {
        font-size: 12px;
        color: #9b9b9b;
        margin-top: 2px;
      }

      .settings-group {
        background: #151515;
        border: 1px solid rgba(255, 255, 255, 0.06);
        border-radius: 12px;
        overflow: hidden;
      }

      .setting-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 16px 20px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.04);
        transition: background 0.15s ease;
      }

      .setting-row:hover {
        background: rgba(255, 255, 255, 0.02);
      }

      .setting-row:last-child {
        border-bottom: none;
      }

      .setting-info {
        flex: 1;
        padding-right: 24px;
        min-width: 0;
      }

      .setting-label {
        font-size: 14px;
        color: #ffffff;
        margin-bottom: 4px;
      }

      .setting-description {
        font-size: 12px;
        color: #9b9b9b;
        line-height: 1.4;
      }

      .setting-control {
        flex-shrink: 0;
      }

      .toggle {
        width: 44px;
        height: 24px;
        background: #2a2a2a;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 12px;
        position: relative;
        cursor: pointer;
        transition: all 0.2s ease;
      }

      .toggle.active {
        background: #ffffff;
        border-color: #ffffff;
      }

      .toggle-knob {
        width: 18px;
        height: 18px;
        background: #ffffff;
        border-radius: 50%;
        position: absolute;
        top: 2px;
        left: 2px;
        transition: all 0.2s ease;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
      }

      .toggle.active .toggle-knob {
        left: 22px;
        background: #000000;
      }

      .select {
        background: #1a1a1a;
        color: #ffffff;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 8px;
        padding: 8px 12px;
        font-size: 13px;
        outline: none;
        cursor: pointer;
        min-width: 140px;
      }

      .select:hover {
        border-color: rgba(255, 255, 255, 0.15);
      }

      .select:focus {
        border-color: rgba(255, 255, 255, 0.3);
      }

      .button {
        background: #1a1a1a;
        color: #ffffff;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 8px;
        padding: 8px 16px;
        font-size: 13px;
        cursor: pointer;
        transition: all 0.15s ease;
      }

      .button:hover {
        background: #252525;
        border-color: rgba(255, 255, 255, 0.15);
      }

      .button.primary {
        background: #ffffff;
        color: #000000;
        border-color: #ffffff;
        font-weight: 500;
      }

      .button.primary:hover {
        background: #f0f0f0;
      }

      .divider {
        height: 1px;
        background: rgba(255, 255, 255, 0.06);
        margin: 32px 0;
      }
    </style>

    <div class="settings-container">
      <div class="settings-header">
        <div class="settings-title">
          <cr-icon icon="settings" style="width: 28px; height: 28px;"></cr-icon>
          <span>Settings</span>
        </div>
        <div class="settings-subtitle">
          Customize your Astra browsing experience
        </div>
      </div>

      <div class="search-section">
        <div class="search-box">
          <cr-icon icon="cr:search" class="search-icon"></cr-icon>
          <input type="text" class="search-input" placeholder="Search settings..." />
        </div>
      </div>

      <div class="nav-grid">
        <div class="nav-card" on-click="openAppearance_">
          <div class="nav-icon">
            <cr-icon icon="settings:appearance"></cr-icon>
          </div>
          <div class="nav-content">
            <div class="nav-title">Appearance</div>
            <div class="nav-desc">Theme, font size, and display preferences</div>
          </div>
        </div>

        <div class="nav-card" on-click="openTabs_">
          <div class="nav-icon">
            <cr-icon icon="settings20:auto-tab-group"></cr-icon>
          </div>
          <div class="nav-content">
            <div class="nav-title">Tabs</div>
            <div class="nav-desc">Tab layout, behavior, and workspace settings</div>
          </div>
        </div>

        <div class="nav-card" on-click="openSearch_">
          <div class="nav-icon">
            <cr-icon icon="cr:search"></cr-icon>
          </div>
          <div class="nav-content">
            <div class="nav-title">Search engine</div>
            <div class="nav-desc">Default search provider and suggestions</div>
          </div>
        </div>

        <div class="nav-card" on-click="openPrivacy_">
          <div class="nav-icon">
            <cr-icon icon="settings:security"></cr-icon>
          </div>
          <div class="nav-content">
            <div class="nav-title">Privacy & Security</div>
            <div class="nav-desc">Cookies, permissions, and security settings</div>
          </div>
        </div>

        <div class="nav-card" on-click="openAutofill_">
          <div class="nav-icon">
            <cr-icon icon="settings:autofill"></cr-icon>
          </div>
          <div class="nav-content">
            <div class="nav-title">Autofill</div>
            <div class="nav-desc">Passwords, payment methods, and addresses</div>
          </div>
        </div>

        <div class="nav-card" on-click="openDownloads_">
          <div class="nav-icon">
            <cr-icon icon="cr:file-download"></cr-icon>
          </div>
          <div class="nav-content">
            <div class="nav-title">Downloads</div>
            <div class="nav-desc">Download location and behavior</div>
          </div>
        </div>
      </div>

      <div class="section">
        <div class="section-header">
          <div class="section-title-group">
            <div>
              <div class="section-title">Quick Settings</div>
              <div class="section-desc">Frequently used preferences</div>
            </div>
          </div>
        </div>
        <div class="settings-group">
          <div class="setting-row">
            <div class="setting-info">
              <div class="setting-label">Dark mode</div>
              <div class="setting-description">Use dark theme for all pages</div>
            </div>
            <div class="setting-control">
              <div class$="[[getToggleClass_(darkMode_)]]" on-click="toggleDarkMode_">
                <div class="toggle-knob"></div>
              </div>
            </div>
          </div>
          <div class="setting-row">
            <div class="setting-info">
              <div class="setting-label">Show bookmarks bar</div>
              <div class="setting-description">Always show the bookmarks toolbar</div>
            </div>
            <div class="setting-control">
              <div class$="[[getToggleClass_(bookmarksBar_)]]" on-click="toggleBookmarksBar_">
                <div class="toggle-knob"></div>
              </div>
            </div>
          </div>
          <div class="setting-row">
            <div class="setting-info">
              <div class="setting-label">Home page</div>
              <div class="setting-description">Page shown when opening a new window</div>
            </div>
            <div class="setting-control">
              <select class="select" value="[[homePage_]]" on-change="onHomePageChange_">
                <option value="newtab">New Tab page</option>
                <option value="astra">Astra homepage</option>
                <option value="custom">Custom URL</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  <!--_html_template_end_-->`;
}

const NewSettingsElementBase = PrefsMixin(BaseMixin(PolymerElement));
class NewSettingsElement extends NewSettingsElementBase {
  static get is() { return 'settings-new'; }
  static get template() { return getTemplateNewSettings(); }
  static get properties() {
    return {
      darkMode_: {
        type: Boolean,
        value: true
      },
      bookmarksBar_: {
        type: Boolean,
        value: false
      },
      homePage_: {
        type: String,
        value: 'newtab'
      }
    };
  }

  getToggleClass_(active) {
    return active ? 'toggle active' : 'toggle';
  }

  toggleDarkMode_() {
    this.set('darkMode_', !this.darkMode_);
  }

  toggleBookmarksBar_() {
    this.set('bookmarksBar_', !this.bookmarksBar_);
  }

  onHomePageChange_(e) {
    this.set('homePage_', e.target.value);
  }

  openAppearance_() {
    window.location.hash = '#/appearance';
  }

  openTabs_() {
    window.location.hash = '#/tabs';
  }

  openSearch_() {
    window.location.hash = '#/search';
  }

  openPrivacy_() {
    window.location.hash = '#/privacy';
  }

  openAutofill_() {
    window.location.hash = '#/autofill';
  }

  openDownloads_() {
    window.location.hash = '#/downloads';
  }
}

customElements.define(NewSettingsElement.is, NewSettingsElement);
