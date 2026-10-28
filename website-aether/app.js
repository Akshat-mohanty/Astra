document.addEventListener('DOMContentLoaded', () => {
  // 1. Interactive Word Reticle Focus Effect
  const wordsContainer = document.getElementById('hero-words-container') || document.querySelector('#hero .relative.flex.gap-4.justify-center.items-center.flex-wrap');
  if (wordsContainer) {
    const wordSpans = wordsContainer.querySelectorAll('.hero-word, span.relative.text-\\[3rem\\]');
    const reticle = document.getElementById('hero-reticle') || wordsContainer.querySelector('.absolute.top-0.left-0.pointer-events-none');
    let currentActiveSpan = null;

    function positionReticle(targetSpan, animate = true) {
      if (!targetSpan || !reticle) return;
      currentActiveSpan = targetSpan;
      
      const containerRect = wordsContainer.getBoundingClientRect();
      const spanRect = targetSpan.getBoundingClientRect();
      
      const left = spanRect.left - containerRect.left;
      const top = spanRect.top - containerRect.top;
      const width = spanRect.width;
      const height = spanRect.height;

      if (animate) {
        reticle.style.transition = 'transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), width 0.3s cubic-bezier(0.16, 1, 0.3, 1), height 0.3s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.2s ease';
      } else {
        reticle.style.transition = 'none';
      }

      reticle.style.transform = `translate(${left}px, ${top}px)`;
      reticle.style.width = `${width}px`;
      reticle.style.height = `${height}px`;
      reticle.style.opacity = '1';

      wordSpans.forEach(span => {
        if (span === targetSpan) {
          span.style.filter = 'blur(0px)';
          span.style.color = '#FFFFFF';
        } else {
          span.style.filter = 'blur(2px)';
          span.style.color = 'rgba(255, 255, 255, 0.8)';
        }
      });
    }

    wordSpans.forEach(span => {
      span.addEventListener('mouseenter', () => positionReticle(span, true));
      span.addEventListener('click', () => positionReticle(span, true));
    });

    // Default position on "craft." or first word
    const defaultSpan = wordSpans[wordSpans.length - 1] || wordSpans[0];
    const syncPosition = (animate = false) => {
      positionReticle(currentActiveSpan || defaultSpan, animate);
    };

    // Immediate calculation
    syncPosition(false);

    // Font readiness check
    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(() => syncPosition(false));
    }

    // Window load & resize
    window.addEventListener('load', () => syncPosition(false));
    window.addEventListener('resize', () => syncPosition(false));

    // Dynamic resize observer for font-swapping or responsive wrapping
    if (window.ResizeObserver) {
      const ro = new ResizeObserver(() => syncPosition(false));
      ro.observe(wordsContainer);
      wordSpans.forEach(span => ro.observe(span));
    }
  }

  // 2. Exact Waitlist Modal
  const modal = document.getElementById('waitlist-modal');
  const form = document.getElementById('waitlist-form');
  const successBox = document.getElementById('waitlist-success');

  function openModal(e) {
    if (e) e.preventDefault();
    if (modal) {
      modal.classList.remove('hidden');
      document.body.style.overflow = 'hidden';
      const emailInput = document.getElementById('waitlist-email');
      if (emailInput) setTimeout(() => emailInput.focus(), 50);
    }
  }

  function closeModal() {
    if (modal) {
      modal.classList.add('hidden');
      document.body.style.overflow = '';
    }
  }

  // Bind to all waitlist buttons on the page
  document.querySelectorAll('button').forEach(btn => {
    const text = btn.textContent.toLowerCase();
    if (text.includes('waitlist')) {
      btn.addEventListener('click', openModal);
    }
  });

  if (modal) {
    modal.addEventListener('click', (e) => {
      // Close when clicking outside the card
      if (e.target === modal || e.target.classList.contains('waitlist-modal-overlay')) {
        closeModal();
      }
    });
  }

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
  });

  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const email = document.getElementById('waitlist-email')?.value;
      if (email) {
        form.style.display = 'none';
        if (successBox) {
          successBox.style.display = 'flex';
        }
      }
    });
  }

  // 3. Ambient Glow Track
  const heroSection = document.getElementById('hero');
  if (heroSection) {
    const glow = heroSection.querySelector('.absolute.inset-0.pointer-events-none');
    heroSection.addEventListener('mousemove', (e) => {
      if (!glow) return;
      const rect = heroSection.getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 100;
      const y = ((e.clientY - rect.top) / rect.height) * 100;
      glow.style.background = `radial-gradient(ellipse 70% 50% at ${x}% ${y}%, rgba(225, 29, 72, 0.18) 0%, rgba(236, 72, 153, 0.07) 40%, transparent 70%)`;
    });
  }
});
