// Search Engine Configuration
const engines = {
  google: 'https://www.google.com/search?q=',
  duckduckgo: 'https://duckduckgo.com/?q=',
  brave: 'https://search.brave.com/search?q=',
  github: 'https://github.com/search?q='
};
let currentEngine = localStorage.getItem('astra_pref_engine') || 'google';

function initEngine() {
  const names = { google: 'Google', duckduckgo: 'DuckDuckGo', brave: 'Brave', github: 'GitHub' };
  const nameEl = document.getElementById('current-engine-name');
  if (nameEl) {
    nameEl.textContent = names[currentEngine] || 'Google';
  }
  document.querySelectorAll('.engine-choice').forEach(btn => {
    btn.classList.toggle('selected', btn.getAttribute('data-engine') === currentEngine);
  });
}

function toggleEngineMenu(e) {
  e.stopPropagation();
  const menu = document.getElementById('engine-menu');
  if (menu) {
    menu.classList.toggle('visible');
  }
}

function selectEngine(id, name) {
  currentEngine = id;
  localStorage.setItem('astra_pref_engine', id);
  const nameEl = document.getElementById('current-engine-name');
  if (nameEl) {
    nameEl.textContent = name;
  }
  const menu = document.getElementById('engine-menu');
  if (menu) {
    menu.classList.remove('visible');
  }
  document.querySelectorAll('.engine-choice').forEach(btn => {
    btn.classList.toggle('selected', btn.getAttribute('data-engine') === id);
  });
  const input = document.getElementById('search-input');
  if (input) {
    input.focus();
  }
}

function executeSearch(e) {
  e.preventDefault();
  const input = document.getElementById('search-input');
  if (!input) return;
  const query = input.value.trim();
  if (!query) return;

  const isUrl = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/.test(query)
             || query.startsWith('localhost')
             || query.includes('://');

  if (isUrl) {
    const dest = query.startsWith('http://') || query.startsWith('https://') ? query : 'https://' + query;
    window.location.href = dest;
  } else {
    const baseUrl = engines[currentEngine] || engines.google;
    window.location.href = baseUrl + encodeURIComponent(query);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  initEngine();

  const engineBtn = document.getElementById('engine-btn');
  if (engineBtn) {
    engineBtn.addEventListener('click', toggleEngineMenu);
  }

  document.querySelectorAll('.engine-choice').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-engine');
      const name = btn.textContent.trim();
      selectEngine(id, name);
    });
  });

  const searchForm = document.getElementById('search-form');
  if (searchForm) {
    searchForm.addEventListener('submit', executeSearch);
  }

  window.addEventListener('click', () => {
    const menu = document.getElementById('engine-menu');
    if (menu) {
      menu.classList.remove('visible');
    }
  });

  window.addEventListener('keydown', (e) => {
    const input = document.getElementById('search-input');
    if (!input) return;
    if ((e.key === '/' || (e.metaKey && e.key === 'k')) && document.activeElement !== input) {
      e.preventDefault();
      input.focus();
      input.select();
    }
  });
});
