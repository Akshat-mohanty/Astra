document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('search-input');
  const searchForm = document.getElementById('search-form');
  const addBtn = document.getElementById('add-btn');
  const fileInput = document.getElementById('file-input');
  const micBtn = document.getElementById('mic-btn');
  const submitBtn = searchForm ? searchForm.querySelector('.submit-arrow-btn') : null;

  // Active state for submit button when input has text
  if (input && submitBtn) {
    input.addEventListener('input', () => {
      const hasText = input.value.trim().length > 0;
      submitBtn.style.color = hasText ? '#ffffff' : '#787878';
      submitBtn.style.background = hasText ? '#4a4a4a' : '#383838';
    });
  }

  // Execute Search or Navigate
  if (searchForm) {
    searchForm.addEventListener('submit', (e) => {
      e.preventDefault();
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
        window.location.href = 'https://www.google.com/search?q=' + encodeURIComponent(query);
      }
    });
  }

  // Add tabs or files
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
        micBtn.style.color = '#ef4444'; // Red recording dot feel

        recognition.onresult = (event) => {
          const transcript = event.results[0][0].transcript;
          input.value = transcript;
          micBtn.style.color = '#787878';
          input.focus();
        };

        recognition.onerror = () => {
          micBtn.style.color = '#787878';
        };

        recognition.onend = () => {
          micBtn.style.color = '#787878';
        };
      } else {
        input.placeholder = "Listening not supported on this engine";
        setTimeout(() => {
          input.placeholder = "Ask anything...";
        }, 2000);
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
