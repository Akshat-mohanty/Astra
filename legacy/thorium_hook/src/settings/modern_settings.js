// Astra Modern Settings - Styled after Astra's clean graphite layout
function getTemplateAstraSettings() {
  return html$1`<!--_html_template_start_-->
    <style include="cr-shared-style settings-shared">
      :host {
        display: flex;
        height: 100vh;
        width: 100%;
        background: #1a1a1d;
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Segoe UI", system-ui, sans-serif;
      }

      .sidebar {
        width: 260px;
        background: #1f1f22;
        border-right: 1px solid rgba(255, 255, 255, 0.07);
        display: flex;
        flex-direction: column;
        padding: 24px 16px;
      }

      .sidebar-header {
        padding: 0 8px 24px 8px;
      }

      .sidebar-title {
        font-size: 14px;
        font-weight: 550;
        color: #f4f4f6;
        letter-spacing: -0.015em;
        margin-bottom: 4px;
      }

      .sidebar-subtitle {
        font-size: 10px;
        font-weight: 550;
        letter-spacing: 0.035em;
        text-transform: uppercase;
        color: rgba(244, 244, 246, 0.44);
      }

      .sidebar-nav {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 3px;
      }

      .nav-item {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 9px 12px;
        border-radius: 12px;
        cursor: pointer;
        transition: all 0.15s ease;
        color: rgba(244, 244, 246, 0.68);
        text-decoration: none;
        border: none;
        background: transparent;
        width: 100%;
        text-align: left;
        font-size: 13px;
        font-family: inherit;
      }

      .nav-item:hover {
        background: rgba(255, 255, 255, 0.04);
        color: #f4f4f6;
      }

      .nav-item.active {
        background: rgba(255, 255, 255, 0.075);
        box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.06);
        color: #f4f4f6;
        font-weight: 500;
      }

      .nav-item-icon {
        width: 18px;
        height: 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
      }

      .main-content {
        flex: 1;
        overflow-y: auto;
        background: #1a1a1d;
      }

      .content-container {
        max-width: 850px;
        margin: 0 auto;
        padding: 52px 36px 64px;
      }

      .page-header {
        margin-bottom: 34px;
      }

      .page-title {
        font-size: 27px;
        font-weight: 550;
        color: #f4f4f6;
        letter-spacing: -0.035em;
        margin-bottom: 8px;
      }

      .page-subtitle {
        font-size: 13px;
        color: rgba(244, 244, 246, 0.68);
        line-height: 1.6;
      }

      .section {
        margin-bottom: 32px;
      }

      .section-card {
        background: #26262a;
        border: 1px solid rgba(255, 255, 255, 0.05);
        border-radius: 18px;
        overflow: hidden;
      }

      .section-header {
        padding: 20px 24px 14px 24px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.07);
      }

      .section-title {
        font-size: 15px;
        font-weight: 600;
        letter-spacing: -0.012em;
        color: #f4f4f6;
        margin-bottom: 4px;
      }

      .section-description {
        font-size: 12.5px;
        color: rgba(244, 244, 246, 0.68);
      }

      .section-content {
        padding: 0;
      }

      .setting-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 14px 24px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.07);
        gap: 24px;
      }

      .setting-row:last-child {
        border-bottom: none;
      }

      .setting-info {
        flex: 1;
        min-width: 0;
      }

      .setting-label {
        font-size: 13.5px;
        font-weight: 500;
        color: #f4f4f6;
        margin-bottom: 2px;
      }

      .setting-description {
        font-size: 12px;
        color: rgba(244, 244, 246, 0.68);
        line-height: 1.5;
      }

      .toggle {
        width: 36px;
        height: 22px;
        background: rgba(255, 255, 255, 0.14);
        border: none;
        border-radius: 999px;
        position: relative;
        cursor: pointer;
        transition: all 0.2s ease;
        flex-shrink: 0;
      }

      .toggle.active {
        background: #ededf0;
      }

      .toggle-thumb {
        width: 18px;
        height: 18px;
        background: #e5e5e8;
        border-radius: 50%;
        position: absolute;
        top: 2px;
        left: 2px;
        transition: all 0.2s ease;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
      }

      .toggle.active .toggle-thumb {
        left: 16px;
        background: #161619;
      }

      .select {
        background: rgba(255, 255, 255, 0.09);
        color: #f4f4f6;
        border: none;
        border-radius: 10px;
        padding: 7px 14px;
        font-size: 12.5px;
        outline: none;
        cursor: pointer;
        min-width: 160px;
        font-family: inherit;
        transition: background 0.15s ease;
      }

      .select:hover {
        background: rgba(255, 255, 255, 0.13);
      }

      .select:focus {
        background: rgba(255, 255, 255, 0.15);
      }

      .btn {
        background: rgba(255, 255, 255, 0.09);
        color: #f4f4f6;
        border: none;
        border-radius: 10px;
        padding: 7px 16px;
        font-size: 12.5px;
        font-weight: 500;
        cursor: pointer;
        font-family: inherit;
        transition: all 0.15s ease;
      }

      .btn:hover {
        background: rgba(255, 255, 255, 0.13);
      }

      .btn-primary {
        background: #ededf0;
        color: #161619;
        font-weight: 500;
      }

      .btn-primary:hover {
        background: #ffffff;
      }
    </style>

    <div class="sidebar">
      <div class="sidebar-header">
        <div class="sidebar-title">Settings</div>
        <div class="sidebar-subtitle">Astra Browser</div>
      </div>
      <nav class="sidebar-nav">
        <button class="nav-item active" on-click="goToGeneral_">
          <div class="nav-item-icon">
            <cr-icon icon="settings"></cr-icon>
          </div>
          <span>General</span>
        </button>
        <button class="nav-item" on-click="goToAppearance_">
          <div class="nav-item-icon">
            <cr-icon icon="settings:appearance"></cr-icon>
          </div>
          <span>Appearance</span>
        </button>
        <button class="nav-item" on-click="goToTabs_">
          <div class="nav-item-icon">
            <cr-icon icon="settings20:auto-tab-group"></cr-icon>
          </div>
          <span>Tabs</span>
        </button>
        <button class="nav-item" on-click="goToSearch_">
          <div class="nav-item-icon">
            <cr-icon icon="cr:search"></cr-icon>
          </div>
          <span>Search</span>
        </button>
        <button class="nav-item" on-click="goToPrivacy_">
          <div class="nav-item-icon">
            <cr-icon icon="settings:security"></cr-icon>
          </div>
          <span>Privacy & Security</span>
        </button>
        <button class="nav-item" on-click="goToAutofill_">
          <div class="nav-item-icon">
            <cr-icon icon="settings:autofill"></cr-icon>
          </div>
          <span>Autofill</span>
        </button>
        <button class="nav-item" on-click="goToDownloads_">
          <div class="nav-item-icon">
            <cr-icon icon="cr:file-download"></cr-icon>
          </div>
          <span>Downloads</span>
        </button>
        <button class="nav-item" on-click="goToAdvanced_">
          <div class="nav-item-icon">
            <cr-icon icon="settings:advanced"></cr-icon>
          </div>
          <span>Advanced</span>
        </button>
      </nav>
    </div>

    <div class="main-content">
      <div class="content-container">
        <div class="page-header">
          <div class="page-title">General</div>
          <div class="page-subtitle">Manage your default browser settings and startup preferences</div>
        </div>

        <div class="section">
          <div class="section-card">
            <div class="section-header">
              <div class="section-title">Startup</div>
              <div class="section-description">Control what happens when Astra starts</div>
            </div>
            <div class="section-content">
              <div class="setting-row">
                <div class="setting-info">
                  <div class="setting-label">On startup</div>
                  <div class="setting-description">Choose what to show when the browser launches</div>
                </div>
                <select class="select">
                  <option>Open the New Tab page</option>
                  <option>Open a specific page or set of pages</option>
                  <option>Continue where you left off</option>
                </select>
              </div>
            </div>
          </div>
        </div>

        <div class="section">
          <div class="section-card">
            <div class="section-header">
              <div class="section-title">Appearance</div>
              <div class="section-description">Customize the look and feel</div>
            </div>
            <div class="section-content">
              <div class="setting-row">
                <div class="setting-info">
                  <div class="setting-label">Show bookmarks bar</div>
                  <div class="setting-description">Always display the bookmarks toolbar</div>
                </div>
                <div class$="[[getToggleClass_(showBookmarks_)]]" on-click="toggleBookmarks_">
                  <div class="toggle-thumb"></div>
                </div>
              </div>
              <div class="setting-row">
                <div class="setting-info">
                  <div class="setting-label">Show home button</div>
                  <div class="setting-description">Display a home button in the toolbar</div>
                </div>
                <div class$="[[getToggleClass_(showHome_)]]" on-click="toggleHome_">
                  <div class="toggle-thumb"></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="section">
          <div class="section-card">
            <div class="section-header">
              <div class="section-title">Search engine</div>
              <div class="setting-description">Manage your default search provider</div>
            </div>
            <div class="section-content">
              <div class="setting-row">
                <div class="setting-info">
                  <div class="setting-label">Search engine used in address bar</div>
                  <div class="setting-description">Choose your default search provider</div>
                </div>
                <select class="select">
                  <option>Google</option>
                  <option>DuckDuckGo</option>
                  <option>Bing</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  <!--_html_template_end_-->`;
}

const AstraSettingsElementBase = PrefsMixin(BaseMixin(PolymerElement));
class AstraSettingsElement extends AstraSettingsElementBase {
  static get is() { return 'astra-settings'; }
  static get template() { return getTemplateAstraSettings(); }
  static get properties() {
    return {
      showBookmarks_: { type: Boolean, value: false },
      showHome_: { type: Boolean, value: false }
    };
  }

  getToggleClass_(active) {
    return active ? 'toggle active' : 'toggle';
  }

  toggleBookmarks_() {
    this.set('showBookmarks_', !this.showBookmarks_);
  }

  toggleHome_() {
    this.set('showHome_', !this.showHome_);
  }

  goToGeneral_() { console.log('general'); }
  goToAppearance_() { console.log('appearance'); }
  goToTabs_() { console.log('tabs'); }
  goToSearch_() { console.log('search'); }
  goToPrivacy_() { console.log('privacy'); }
  goToAutofill_() { console.log('autofill'); }
  goToDownloads_() { console.log('downloads'); }
  goToAdvanced_() { console.log('advanced'); }
}

customElements.define(AstraSettingsElement.is, AstraSettingsElement);
