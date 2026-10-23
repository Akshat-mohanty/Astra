// Astra Root WebUI Component: <settings-tabs-page>
// Integrates directly into Chromium's native <settings-ui> component tree (Polymer/Lit)

function getTemplateTabs() {
  return html$1`<!--_html_template_start_-->
    <style include="cr-shared-style settings-shared">
      .tab-card-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 16px;
        margin: 16px 0 24px 0;
      }
      .tab-card {
        border: 2px solid var(--cr-separator-color, rgba(255,255,255,0.1));
        border-radius: var(--cr-card-border-radius, 12px);
        padding: 16px;
        cursor: pointer;
        transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        display: flex;
        flex-direction: column;
        gap: 12px;
        background: var(--cr-card-background-color, rgba(255,255,255,0.02));
      }
      .tab-card:hover {
        background: var(--cr-hover-background-color, rgba(255,255,255,0.06));
        border-color: rgba(255,255,255,0.25);
      }
      .tab-card[active] {
        border-color: var(--cr-focus-outline-color, #7c5cfc);
        background: var(--cr-active-background-color, rgba(124, 92, 252, 0.08));
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
      }
      .preview-window {
        height: 100px;
        border-radius: 8px;
        border: 1px solid rgba(255,255,255,0.12);
        background: #141416;
        position: relative;
        overflow: hidden;
        display: flex;
        flex-direction: column;
      }
      .preview-top-bar {
        height: 22px;
        background: #202024;
        border-bottom: 1px solid rgba(255,255,255,0.08);
        display: flex;
        align-items: center;
        padding: 0 8px;
        gap: 6px;
      }
      .mock-dot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        background: rgba(255,255,255,0.2);
      }
      .preview-h-tab {
        height: 14px;
        padding: 0 8px;
        border-radius: 4px;
        background: rgba(255,255,255,0.08);
        font-size: 8px;
        display: flex;
        align-items: center;
        color: #888;
      }
      .preview-h-tab.active {
        background: #7c5cfc;
        color: #fff;
        font-weight: 600;
      }
      .preview-v-layout {
        display: flex;
        flex: 1;
        height: 100%;
      }
      .preview-v-sidebar {
        width: 54px;
        background: #1c1c1f;
        border-right: 1px solid rgba(255,255,255,0.08);
        display: flex;
        flex-direction: column;
        padding: 6px 4px;
        gap: 4px;
      }
      .preview-v-item {
        height: 14px;
        border-radius: 4px;
        background: rgba(255,255,255,0.06);
        padding: 0 4px;
        font-size: 7.5px;
        display: flex;
        align-items: center;
        color: #888;
      }
      .preview-v-item.active {
        background: rgba(124, 92, 252, 0.25);
        color: #fff;
        border-left: 2px solid #7c5cfc;
        font-weight: 600;
      }
      .preview-body {
        flex: 1;
        background: #121214;
        padding: 8px;
        display: flex;
        flex-direction: column;
        gap: 6px;
      }
      .mock-line {
        height: 6px;
        border-radius: 3px;
        background: rgba(255,255,255,0.06);
        width: 70%;
      }
      .card-meta-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
      }
      .card-heading {
        font-size: 14.5px;
        font-weight: 550;
        color: var(--cr-primary-text-color, #fff);
        display: flex;
        align-items: center;
        gap: 8px;
      }
      .card-tag {
        font-size: 10px;
        font-weight: 600;
        text-transform: uppercase;
        padding: 2px 7px;
        border-radius: 4px;
        background: rgba(124, 92, 252, 0.18);
        color: #a78bfa;
      }
      .card-desc {
        font-size: 12px;
        line-height: 1.45;
        color: var(--cr-secondary-text-color, #999);
      }
    </style>

    <div class="cr-row first">
      <div class="flex cr-padded-text">
        <div class="card-heading">Tab Orientation</div>
        <div class="card-desc">Configure whether tabs appear across the top or assigned as an ergonomic sidebar to the left of the screen.</div>
      </div>
    </div>

    <div class="tab-card-grid">
      <!-- Horizontal Card -->
      <div class="tab-card" active$="[[!isVertical_]]" on-click="setOrientationHorizontal_">
        <div class="preview-window">
          <div class="preview-top-bar">
            <span class="mock-dot"></span><span class="mock-dot"></span><span class="mock-dot"></span>
            <div class="preview-h-tab active">Tab 1</div>
            <div class="preview-h-tab">Tab 2</div>
          </div>
          <div class="preview-body">
            <div class="mock-line" style="width: 50%;"></div>
            <div class="mock-line" style="width: 80%;"></div>
          </div>
        </div>
        <div class="card-meta-row">
          <span class="card-heading">
            Horizontal Tabs
            <template is="dom-if" if="[[!isVertical_]]">
              <span class="card-tag">Current</span>
            </template>
          </span>
          <cr-radio-button checked="[[!isVertical_]]" no-label></cr-radio-button>
        </div>
        <div class="card-desc">Classic tab strip arranged horizontally across the top of the browser window.</div>
      </div>

      <!-- Vertical Card -->
      <div class="tab-card" active$="[[isVertical_]]" on-click="setOrientationVertical_">
        <div class="preview-window">
          <div class="preview-v-layout">
            <div class="preview-v-sidebar">
              <div style="display: flex; gap: 3px; margin-bottom: 4px;">
                <span class="mock-dot" style="width: 4px; height: 4px;"></span>
                <span class="mock-dot" style="width: 4px; height: 4px;"></span>
                <span class="mock-dot" style="width: 4px; height: 4px;"></span>
              </div>
              <div class="preview-v-item active">Tab 1</div>
              <div class="preview-v-item">Tab 2</div>
              <div class="preview-v-item">Tab 3</div>
            </div>
            <div class="preview-body">
              <div class="mock-line" style="width: 60%;"></div>
              <div class="mock-line" style="width: 85%;"></div>
            </div>
          </div>
        </div>
        <div class="card-meta-row">
          <span class="card-heading">
            Vertical Tabs
            <template is="dom-if" if="[[isVertical_]]">
              <span class="card-tag">Current</span>
            </template>
            <template is="dom-if" if="[[!isVertical_]]">
              <span class="card-tag">Assigned to Left</span>
            </template>
          </span>
          <cr-radio-button checked="[[isVertical_]]" no-label></cr-radio-button>
        </div>
        <div class="card-desc">Tabs are assigned to the left of the screen as an ergonomic sidebar (Arc & Dia style).</div>
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
        value() {
          try {
            const saved = localStorage.getItem('astra_settings');
            if (saved) return JSON.parse(saved).tab_orientation || 'horizontal';
          } catch(e) {}
          return 'horizontal';
        }
      },
      isVertical_: {
        type: Boolean,
        computed: 'computeIsVertical_(orientation_)'
      }
    };
  }

  computeIsVertical_(orientation) {
    return orientation === 'vertical';
  }

  setOrientationHorizontal_() {
    this.orientation_ = 'horizontal';
    this.saveOrientation_('horizontal');
  }

  setOrientationVertical_() {
    this.orientation_ = 'vertical';
    this.saveOrientation_('vertical');
  }

  saveOrientation_(val) {
    try {
      let saved = {};
      const raw = localStorage.getItem('astra_settings');
      if (raw) saved = JSON.parse(raw);
      saved.tab_orientation = val;
      localStorage.setItem('astra_settings', JSON.stringify(saved));
      window.dispatchEvent(new CustomEvent('astra-settings-updated', { detail: saved }));
    } catch(err) {}
  }
}
customElements.define(SettingsTabsPageElement.is, SettingsTabsPageElement);
