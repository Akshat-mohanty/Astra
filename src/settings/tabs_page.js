// Astra Root WebUI Component: <settings-tabs-page>
// Integrates directly into Chromium's native <settings-ui> component tree (Polymer/Lit)

function getTemplateTabs() {
  return html$1`<!--_html_template_start_-->
    <style include="cr-shared-style settings-shared">
      :host {
        display: block;
        padding: 0 0 32px 0;
        position: relative;
        min-height: 100%;
      }

      .tabs-section-header {
        margin-bottom: 20px;
        padding: 0 4px;
        position: relative;
        z-index: 1;
      }

      .tabs-main-title {
        font-size: 19px;
        font-weight: 600;
        letter-spacing: -0.3px;
        color: var(--cr-primary-text-color, #f4f3ef);
        display: flex;
        align-items: center;
        gap: 10px;
        line-height: 1.3;
      }

      .tabs-main-subtitle {
        font-size: 13px;
        line-height: 1.5;
        color: var(--cr-secondary-text-color, #929298);
        margin-top: 4px;
        max-width: 620px;
      }

      .group-card {
        background: var(--cr-card-background-color, #18181b);
        border: 1px solid var(--cr-separator-color, rgba(255, 255, 255, 0.08));
        border-radius: var(--cr-card-border-radius, 16px);
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25);
        position: relative;
        transform: translateZ(0);
      }

      .group-card-title {
        font-size: 14px;
        font-weight: 600;
        color: var(--cr-primary-text-color, #f4f3ef);
        margin-bottom: 4px;
      }

      .group-card-subtitle {
        font-size: 12.5px;
        color: var(--cr-secondary-text-color, #8e8e93);
        margin-bottom: 16px;
      }

      /* Orientation Cards Grid */
      .orientation-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 16px;
        align-items: start;
      }

      .orientation-card {
        position: relative;
        border: 2px solid rgba(255, 255, 255, 0.08);
        border-radius: 14px;
        background: rgba(255, 255, 255, 0.02);
        padding: 16px;
        cursor: pointer;
        display: flex;
        flex-direction: column;
        gap: 14px;
        transition: border-color 0.2s ease, background 0.2s ease, box-shadow 0.2s ease;
        user-select: none;
      }

      .orientation-card * {
        pointer-events: none;
      }

      .orientation-card:hover {
        border-color: rgba(255, 255, 255, 0.2);
        background: rgba(255, 255, 255, 0.04);
      }

      .orientation-card.active,
      .orientation-card[active="true"] {
        border-color: rgba(255, 255, 255, 0.4);
        background: rgba(255, 255, 255, 0.08);
        box-shadow: 0 8px 28px rgba(0, 0, 0, 0.45);
      }

      /* Mock Window Previews */
      .mock-window {
        height: 120px;
        border-radius: 10px;
        background: #0f0f11;
        border: 1px solid rgba(255, 255, 255, 0.1);
        overflow: hidden;
        display: flex;
        flex-direction: column;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.45);
        flex-shrink: 0;
      }

      /* Horizontal Window */
      .mock-h-topbar {
        height: 28px;
        background: #1b1b1e;
        border-bottom: 1px solid rgba(255, 255, 255, 0.08);
        display: flex;
        align-items: center;
        padding: 0 10px;
        gap: 8px;
      }

      .mock-traffic-lights {
        display: flex;
        align-items: center;
        gap: 5px;
      }

      .mock-traffic-dot {
        width: 7px;
        height: 7px;
        border-radius: 50%;
        opacity: 0.8;
      }

      .mock-traffic-dot.red { background: #ff5f57; }
      .mock-traffic-dot.yellow { background: #febc2e; }
      .mock-traffic-dot.green { background: #28c840; }

      .mock-tab-strip {
        display: flex;
        align-items: center;
        gap: 5px;
        margin-left: 6px;
      }

      .mock-h-tab {
        height: 18px;
        padding: 0 10px;
        border-radius: 5px;
        font-size: 9px;
        font-weight: 500;
        display: flex;
        align-items: center;
        gap: 4px;
        background: rgba(255, 255, 255, 0.06);
        color: #88888b;
      }

      .mock-h-tab.active {
        background: #ffffff;
        color: #000000;
        font-weight: 600;
        box-shadow: 0 2px 6px rgba(255, 255, 255, 0.25);
      }

      .mock-h-tab-add {
        font-size: 11px;
        color: #71717a;
        padding: 0 4px;
      }

      .mock-viewport {
        flex: 1;
        background: #121214;
        padding: 10px 14px;
        display: flex;
        flex-direction: column;
        gap: 7px;
      }

      .mock-address-bar {
        height: 10px;
        width: 45%;
        border-radius: 4px;
        background: rgba(255, 255, 255, 0.06);
        margin-bottom: 4px;
      }

      .mock-content-line {
        height: 6px;
        border-radius: 3px;
        background: rgba(255, 255, 255, 0.04);
      }

      /* Vertical Window */
      .mock-v-container {
        display: flex;
        flex: 1;
        height: 100%;
      }

      .mock-v-sidebar {
        width: 72px;
        background: #17171a;
        border-right: 1px solid rgba(255, 255, 255, 0.08);
        display: flex;
        flex-direction: column;
        padding: 8px 6px;
        gap: 5px;
      }

      .mock-v-brand {
        display: flex;
        align-items: center;
        gap: 4px;
        margin-bottom: 4px;
      }

      .mock-v-new-btn {
        height: 15px;
        border-radius: 4px;
        background: rgba(255, 255, 255, 0.06);
        font-size: 8px;
        color: #d1d1d6;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 500;
        margin-bottom: 2px;
      }

      .mock-v-tab {
        height: 15px;
        border-radius: 4px;
        background: rgba(255, 255, 255, 0.04);
        padding: 0 6px;
        font-size: 8px;
        display: flex;
        align-items: center;
        gap: 4px;
        color: #88888b;
      }

      .mock-v-tab.active {
        background: rgba(255, 255, 255, 0.15);
        border-left: 2px solid #ffffff;
        color: #ffffff;
        font-weight: 600;
      }

      .mock-v-dot {
        width: 4px;
        height: 4px;
        border-radius: 50%;
        background: currentColor;
      }

      /* Card Labels and Meta */
      .card-meta-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
      }

      .card-title-group {
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .card-name {
        font-size: 15px;
        font-weight: 600;
        color: var(--cr-primary-text-color, #f4f3ef);
      }

      .badge-tag {
        font-size: 10px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.4px;
        padding: 2px 7px;
        border-radius: 4px;
        background: rgba(255, 255, 255, 0.08);
        color: #a1a1aa;
      }

      .badge-tag.highlight {
        background: rgba(255, 255, 255, 0.12);
        color: #ffffff;
        border: 1px solid rgba(255, 255, 255, 0.25);
      }

      .card-description {
        font-size: 12.5px;
        line-height: 1.45;
        color: var(--cr-secondary-text-color, #8e8e93);
      }

      /* Radio Circle */
      .custom-radio-circle {
        width: 18px;
        height: 18px;
        border-radius: 50%;
        border: 2px solid #4a4a50;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s ease;
        flex-shrink: 0;
      }

      .orientation-card.active .custom-radio-circle,
      .orientation-card[active="true"] .custom-radio-circle {
        border-color: #ffffff;
        background: #ffffff;
      }

      .custom-radio-circle::after {
        content: '';
        width: 6px;
        height: 6px;
        border-radius: 50%;
        background: #000000;
        opacity: 0;
        transition: opacity 0.15s ease;
      }

      .orientation-card.active .custom-radio-circle::after,
      .orientation-card[active="true"] .custom-radio-circle::after {
        opacity: 1;
      }

      /* Settings Row Inside Group */
      .setting-item-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 14px 0;
        border-bottom: 1px solid rgba(255, 255, 255, 0.06);
        min-height: 52px;
      }

      .setting-item-row:last-child {
        border-bottom: none;
        padding-bottom: 0;
      }

      .setting-item-row.first {
        padding-top: 0;
      }

      .setting-text-col {
        flex: 1;
        padding-right: 24px;
      }

      .setting-item-title {
        font-size: 13.5px;
        font-weight: 500;
        color: var(--cr-primary-text-color, #f4f3ef);
      }

      .setting-item-desc {
        font-size: 12px;
        color: var(--cr-secondary-text-color, #8e8e93);
        margin-top: 2px;
        line-height: 1.4;
      }

      /* Segmented Control */
      .segmented-control {
        display: flex;
        background: #111113;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 8px;
        padding: 3px;
        gap: 3px;
      }

      .segmented-btn {
        background: transparent;
        border: none;
        color: #8e8e93;
        font-size: 12px;
        font-weight: 500;
        padding: 6px 14px;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.15s ease;
        white-space: nowrap;
      }

      .segmented-btn:hover {
        color: #f4f3ef;
      }

      .segmented-btn[active] {
        background: #27272a;
        color: #ffffff;
        font-weight: 600;
        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
      }

      /* Native Select Dropdown */
      .native-select {
        background: #18181b;
        color: #f4f3ef;
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 8px;
        padding: 6px 12px;
        font-size: 12.5px;
        outline: none;
        cursor: pointer;
      }

      .native-select:focus {
        border-color: rgba(255, 255, 255, 0.5);
      }
    </style>

    <div class="tabs-section-header">
      <div class="tabs-main-title">
        <cr-icon icon="settings20:auto-tab-group" style="color: #ffffff;"></cr-icon>
        <span>Tabs & Workspace Layout</span>
      </div>
      <div class="tabs-main-subtitle">
        Configure how tabs are laid out on screen, choose between horizontal and left-docked vertical orientation, and fine-tune sidebar behaviors.
      </div>
    </div>

    <!-- Group 1: Tab Orientation -->
    <div class="group-card">
      <div class="group-card-title">Tab Orientation</div>
      <div class="group-card-subtitle">Choose whether tabs appear across the top or assigned as an ergonomic sidebar to the left of the screen.</div>

      <div class="orientation-grid">
        <!-- Horizontal Card -->
        <div class$="[[computeCardClass_(isHorizontal_)]]" id="cardHorizontal" active$="[[computeActiveAttr_(isHorizontal_)]]" on-click="setOrientationHorizontal_">
          <div class="mock-window">
            <div class="mock-h-topbar">
              <div class="mock-traffic-lights">
                <span class="mock-traffic-dot red"></span>
                <span class="mock-traffic-dot yellow"></span>
                <span class="mock-traffic-dot green"></span>
              </div>
              <div class="mock-tab-strip">
                <div class="mock-h-tab active">New Tab</div>
                <div class="mock-h-tab">GitHub</div>
                <div class="mock-h-tab-add">+</div>
              </div>
            </div>
            <div class="mock-viewport">
              <div class="mock-address-bar"></div>
              <div class="mock-content-line" style="width: 70%;"></div>
              <div class="mock-content-line" style="width: 88%;"></div>
              <div class="mock-content-line" style="width: 55%;"></div>
            </div>
          </div>

          <div class="card-meta-row">
            <div class="card-title-group">
              <span class="card-name">Horizontal Tabs</span>
              <template is="dom-if" if="[[isHorizontal_]]">
                <span class="badge-tag highlight">Current</span>
              </template>
            </div>
            <div class="custom-radio-circle"></div>
          </div>
          <div class="card-description">Classic tab strip positioned horizontally across the top of the browser window.</div>
        </div>

        <!-- Vertical Card -->
        <div class$="[[computeCardClass_(isVertical_)]]" id="cardVertical" active$="[[computeActiveAttr_(isVertical_)]]" on-click="setOrientationVertical_">
          <div class="mock-window">
            <div class="mock-v-container">
              <div class="mock-v-sidebar">
                <div class="mock-v-brand">
                  <span class="mock-traffic-dot red" style="width: 5px; height: 5px;"></span>
                  <span class="mock-traffic-dot yellow" style="width: 5px; height: 5px;"></span>
                  <span class="mock-traffic-dot green" style="width: 5px; height: 5px;"></span>
                </div>
                <div class="mock-v-tab active">New Tab</div>
                <div class="mock-v-tab">GitHub</div>
                <div class="mock-v-tab">Google</div>
              </div>
              <div class="mock-viewport">
                <div class="mock-address-bar" style="width: 60%;"></div>
                <div class="mock-content-line" style="width: 80%;"></div>
                <div class="mock-content-line" style="width: 65%;"></div>
                <div class="mock-content-line" style="width: 90%;"></div>
              </div>
            </div>
          </div>

          <div class="card-meta-row">
            <div class="card-title-group">
              <span class="card-name">Vertical Tabs</span>
              <template is="dom-if" if="[[isVertical_]]">
                <span class="badge-tag highlight">Current</span>
              </template>
            </div>
            <div class="custom-radio-circle"></div>
          </div>
          <div class="card-description">Tabs are assigned to the left of the screen as an ergonomic vertical sidebar (Arc & Dia style).</div>
        </div>
      </div>
    </div>

    <!-- Group 2: Vertical Tab Sidebar Preferences (Active when Vertical Tabs is selected) -->
    <template is="dom-if" if="[[isVertical_]]" restamp>
      <div class="group-card">
        <div class="group-card-title">Vertical Tab Preferences</div>
        <div class="group-card-subtitle">Fine-tune the behavior and appearance of the left sidebar.</div>

        <div class="setting-item-row first">
          <div class="setting-text-col">
            <div class="setting-item-title">Sidebar Width</div>
            <div class="setting-item-desc">Choose between an expanded sidebar with full page titles or an ultra-compact icon strip.</div>
          </div>
          <div class="segmented-control">
            <button type="button" class="segmented-btn" active$="[[isExpandedWidth_(vtabWidth_)]]" on-click="setWidthExpanded_">Expanded (220px)</button>
            <button type="button" class="segmented-btn" active$="[[isCompactWidth_(vtabWidth_)]]" on-click="setWidthCompact_">Compact (56px)</button>
          </div>
        </div>

        <div class="setting-item-row">
          <div class="setting-text-col">
            <div class="setting-item-title">Auto-Collapse Sidebar</div>
            <div class="setting-item-desc">Automatically collapses the left sidebar into compact icon mode when browsing web content.</div>
          </div>
          <cr-toggle checked="[[autoCollapse_]]" on-change="onAutoCollapseToggle_"></cr-toggle>
        </div>

        <div class="setting-item-row">
          <div class="setting-text-col">
            <div class="setting-item-title">Hover-Only Close Buttons</div>
            <div class="setting-item-desc">Keep the vertical tab list uncluttered by revealing close buttons only on pointer hover.</div>
          </div>
          <cr-toggle checked="[[hoverClose_]]" on-change="onHoverCloseToggle_"></cr-toggle>
        </div>
      </div>
    </template>

    <!-- Group 3: Tab Workflow & Audio -->
    <div class="group-card">
      <div class="group-card-title">Tab Workflow & Audio</div>
      <div class="group-card-subtitle">Control where new tabs open and how tabs communicate status.</div>

      <div class="setting-item-row first">
        <div class="setting-text-col">
          <div class="setting-item-title">New Tab Placement</div>
          <div class="setting-item-desc">Choose where newly opened tabs are inserted into your active stack.</div>
        </div>
        <select class="native-select" value="[[tabPosition_]]" on-change="onTabPositionChange_">
          <option value="after_current">After current tab</option>
          <option value="at_end">At the end of tab stack</option>
        </select>
      </div>

      <div class="setting-item-row">
        <div class="setting-text-col">
          <div class="setting-item-title">Tab Audio Indicators</div>
          <div class="setting-item-desc">Display animated sound wave icon and 1-click mute on tabs playing audio.</div>
        </div>
        <cr-toggle checked="[[tabAudio_]]" on-change="onTabAudioToggle_"></cr-toggle>
      </div>

      <div class="setting-item-row">
        <div class="setting-text-col">
          <div class="setting-item-title">Tab Hover Previews</div>
          <div class="setting-item-desc">Show rich card preview and domain details when hovering over background tabs.</div>
        </div>
        <cr-toggle checked="[[tabPreview_]]" on-change="onTabPreviewToggle_"></cr-toggle>
      </div>
    </div>
  <!--_html_template_end_-->`;
}

const SettingsTabsPageElementBase = PrefsMixin(BaseMixin(PolymerElement));
class SettingsTabsPageElement extends SettingsTabsPageElementBase {
  static get is() { return 'settings-tabs-page'; }
  static get template() { return getTemplateTabs(); }
  static get properties() {
    return {
      orientation_: {
        type: String,
        notify: true,
        value() {
          try {
            const saved = localStorage.getItem('astra_settings');
            if (saved) {
              const parsed = JSON.parse(saved);
              if (parsed.tab_orientation) return parsed.tab_orientation;
            }
          } catch(e) {}
          return 'vertical';
        }
      },
      isHorizontal_: {
        type: Boolean,
        computed: 'computeIsHorizontal_(orientation_)'
      },
      isVertical_: {
        type: Boolean,
        computed: 'computeIsVertical_(orientation_)'
      },
      vtabWidth_: {
        type: String,
        notify: true,
        value() {
          try {
            const saved = localStorage.getItem('astra_settings');
            if (saved) return JSON.parse(saved).vtab_width || 'expanded';
          } catch(e) {}
          return 'expanded';
        }
      },
      autoCollapse_: {
        type: Boolean,
        notify: true,
        value() {
          try {
            const saved = localStorage.getItem('astra_settings');
            if (saved) return !!JSON.parse(saved).auto_collapse_tabs;
          } catch(e) {}
          return false;
        }
      },
      hoverClose_: {
        type: Boolean,
        notify: true,
        value() {
          try {
            const saved = localStorage.getItem('astra_settings');
            if (saved) {
              const parsed = JSON.parse(saved);
              if (parsed.tab_hover_close !== undefined) return !!parsed.tab_hover_close;
            }
          } catch(e) {}
          return true;
        }
      },
      tabPosition_: {
        type: String,
        notify: true,
        value() {
          try {
            const saved = localStorage.getItem('astra_settings');
            if (saved) return JSON.parse(saved).tab_position || 'after_current';
          } catch(e) {}
          return 'after_current';
        }
      },
      tabAudio_: {
        type: Boolean,
        value: true
      },
      tabPreview_: {
        type: Boolean,
        value: true
      }
    };
  }

  connectedCallback() {
    super.connectedCallback();
    // Ensure host element has stable positioning within Chromium settings container
    const host = this;
    if (host && host.style) {
      host.style.contain = 'layout style';
    }
    this.addEventListener('click', (e) => {
      const path = (e.composedPath && e.composedPath()) || [];
      for (const el of path) {
        if (!el || !el.getAttribute) continue;
        const id = el.getAttribute('id');
        if (id === 'cardHorizontal') {
          this.setOrientationHorizontal_();
          break;
        } else if (id === 'cardVertical') {
          this.setOrientationVertical_();
          break;
        }
      }
    });
  }

  ready() {
    super.ready();
    const syncFromStorage = () => {
      try {
        const saved = localStorage.getItem('astra_settings');
        if (saved) {
          const parsed = JSON.parse(saved);
          const ori = parsed.tab_orientation || 'vertical';
          this.set('orientation_', ori);
          this.set('isHorizontal_', ori === 'horizontal');
          this.set('isVertical_', ori === 'vertical');
          if (parsed.vtab_width) {
            this.set('vtabWidth_', parsed.vtab_width);
          }
        }
      } catch(e) {}
    };
    syncFromStorage();

    setTimeout(() => {
      const hCard = this.shadowRoot && this.shadowRoot.querySelector('#cardHorizontal');
      if (hCard) {
        hCard.onclick = () => this.setOrientationHorizontal_();
      }
      const vCard = this.shadowRoot && this.shadowRoot.querySelector('#cardVertical');
      if (vCard) {
        vCard.onclick = () => this.setOrientationVertical_();
      }
    }, 0);
  }

  computeIsHorizontal_(orientation) {
    return orientation === 'horizontal';
  }

  computeIsVertical_(orientation) {
    return orientation === 'vertical';
  }

  computeCardClass_(isActive) {
    return isActive ? 'orientation-card active' : 'orientation-card';
  }

  computeActiveAttr_(isActive) {
    return isActive ? 'true' : 'false';
  }

  isExpandedWidth_(width) {
    return width !== 'compact';
  }

  isCompactWidth_(width) {
    return width === 'compact';
  }

  setOrientationHorizontal_() {
    this.set('orientation_', 'horizontal');
    this.set('isHorizontal_', true);
    this.set('isVertical_', false);
    this.saveSetting_('tab_orientation', 'horizontal');
  }

  setOrientationVertical_() {
    this.set('orientation_', 'vertical');
    this.set('isHorizontal_', false);
    this.set('isVertical_', true);
    this.saveSetting_('tab_orientation', 'vertical');
  }

  setWidthExpanded_() {
    this.set('vtabWidth_', 'expanded');
    this.saveSetting_('vtab_width', 'expanded');
  }

  setWidthCompact_() {
    this.set('vtabWidth_', 'compact');
    this.saveSetting_('vtab_width', 'compact');
  }

  onAutoCollapseToggle_(e) {
    const val = e.target.checked;
    this.set('autoCollapse_', val);
    this.saveSetting_('auto_collapse_tabs', val);
  }

  onHoverCloseToggle_(e) {
    const val = e.target.checked;
    this.set('hoverClose_', val);
    this.saveSetting_('tab_hover_close', val);
  }

  onTabPositionChange_(e) {
    const val = e.target.value;
    this.set('tabPosition_', val);
    this.saveSetting_('tab_position', val);
  }

  onTabAudioToggle_(e) {
    this.set('tabAudio_', e.target.checked);
    this.saveSetting_('tab_audio', e.target.checked);
  }

  onTabPreviewToggle_(e) {
    this.set('tabPreview_', e.target.checked);
    this.saveSetting_('tab_preview', e.target.checked);
  }

  saveSetting_(key, val) {
    let saved = {};
    try {
      const raw = localStorage.getItem('astra_settings');
      if (raw) saved = JSON.parse(raw);
    } catch(err) {}
    saved[key] = val;
    try {
      localStorage.setItem('astra_settings', JSON.stringify(saved));
      window.dispatchEvent(new CustomEvent('astra-settings-updated', { detail: saved }));
    } catch(err) {}

    const jsonStr = encodeURIComponent(JSON.stringify(saved));
    const cmd = '__astra_cmd__:key=' + encodeURIComponent(key) + '&val=' + encodeURIComponent(val) + '&json=' + jsonStr;
    try {
      document.title = cmd;
    } catch(e) {}

    const url = 'http://127.0.0.1:4545/api/setting?key=' + encodeURIComponent(key) + '&val=' + encodeURIComponent(val) + '&json=' + jsonStr + '&t=' + Date.now();

    try {
      fetch(url, { method: 'GET', mode: 'cors', cache: 'no-store' }).catch(() => {
        fetch(url, { method: 'GET', mode: 'no-cors', cache: 'no-store' }).catch(() => {});
      });
    } catch(e) {}

    try {
      if (navigator.sendBeacon) {
        navigator.sendBeacon(url);
      }
    } catch(e) {}

    try {
      const xhr = new XMLHttpRequest();
      xhr.open('GET', url, true);
      xhr.send();
    } catch(e) {}
  }
}
customElements.define(SettingsTabsPageElement.is, SettingsTabsPageElement);
