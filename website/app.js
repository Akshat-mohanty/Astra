document.addEventListener('DOMContentLoaded', () => {
  // 1. Mobile Menu Toggle
  const mobileMenuBtn = document.querySelector('header button[aria-label="Open menu"], header .800\\:hidden button, header button');
  const mobileNav = document.getElementById('mobile-navigation-menu');
  const mobileHeaderBox = document.querySelector('header .800\\:hidden') || document.querySelector('header > div:first-child');

  let menuOpen = false;
  if (mobileMenuBtn && mobileNav) {
    mobileMenuBtn.addEventListener('click', (e) => {
      e.preventDefault();
      menuOpen = !menuOpen;
      if (menuOpen) {
        mobileNav.style.opacity = '1';
        mobileNav.style.height = 'auto';
        mobileNav.style.pointerEvents = 'auto';
        if (mobileHeaderBox) mobileHeaderBox.style.height = 'auto';
        mobileNav.querySelectorAll('li, div, button').forEach(el => {
          el.style.opacity = '1';
          el.style.filter = 'none';
        });
      } else {
        mobileNav.style.opacity = '0';
        mobileNav.style.height = '0px';
        mobileNav.style.pointerEvents = 'none';
        if (mobileHeaderBox) mobileHeaderBox.style.height = '52px';
      }
    });
  }

  // 2. Desktop Use Cases Interactive Tabs
  const useCaseButtons = document.querySelectorAll('nav[aria-label="Use cases"] button');
  const useCaseItems = document.querySelectorAll('.col-span-8.flex.flex-col > div');

  function setActiveUseCase(index) {
    useCaseButtons.forEach((btn, idx) => {
      const activeBar = btn.querySelector('.absolute.left-0');
      const descGrid = btn.querySelector('.grid.overflow-hidden');
      
      if (idx === index) {
        btn.classList.add('bg-primary/[0.06]');
        if (activeBar) {
          activeBar.classList.remove('opacity-0', 'bg-transparent');
          activeBar.classList.add('bg-primary', 'opacity-100');
        }
        if (descGrid) {
          descGrid.style.gridTemplateRows = '1fr';
          descGrid.style.opacity = '1';
        }
      } else {
        btn.classList.remove('bg-primary/[0.06]');
        if (activeBar) {
          activeBar.classList.remove('bg-primary', 'opacity-100');
          activeBar.classList.add('opacity-0', 'bg-transparent');
        }
        if (descGrid) {
          descGrid.style.gridTemplateRows = '0fr';
          descGrid.style.opacity = '0';
        }
      }
    });
  }

  useCaseButtons.forEach((btn, index) => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      setActiveUseCase(index);
      if (useCaseItems[index]) {
        useCaseItems[index].scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    });
  });

  // Sync active tab on scroll
  if (useCaseItems.length > 0 && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const idx = Array.from(useCaseItems).indexOf(entry.target);
          if (idx !== -1) {
            setActiveUseCase(idx);
          }
        }
      });
    }, { threshold: 0.5 });

    useCaseItems.forEach(item => observer.observe(item));
  }

  // 3. Interactive Privacy Toggle Marquee
  const toggleButtons = document.querySelectorAll('[data-feature-on]');
  toggleButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const current = btn.getAttribute('data-feature-on') === 'true';
      const newState = !current;
      btn.setAttribute('data-feature-on', newState ? 'true' : 'false');
      
      const dot = btn.querySelector('.rounded-full');
      if (dot) {
        dot.setAttribute('data-feature-on', newState ? 'true' : 'false');
        dot.style.backgroundColor = newState ? '#F2FCB3' : '#FFDC5C';
      }

      const label = btn.querySelector('.w-37, .text-center');
      if (label) {
        label.textContent = newState ? 'On' : 'Off';
      }

      // Visual click bounce
      btn.style.transform = 'scale(0.96)';
      setTimeout(() => {
        btn.style.transform = 'none';
      }, 150);
    });
  });

  // 4. Hero Dock & Arc Scroll Response
  const dock = document.querySelector('[data-sunrise-download="true"]');
  const halo = document.querySelector('[data-sunrise-yellow-halo="true"]');
  const dockShadow = document.querySelector('[data-sunrise-dock-shadow="true"]');

  function updateDockScroll() {
    const scrollY = window.scrollY;
    const heroHeight = window.innerHeight;
    const progress = Math.min(Math.max(scrollY / (heroHeight * 0.7), 0), 1);

    if (dock) {
      dock.style.setProperty('--dock-t', progress);
      dock.style.setProperty('--dock-arc', Math.max(0.2, 1 - progress * 0.8));
      dock.style.setProperty('--dock-pill', Math.min(1, 0.9 + progress * 0.1));
    }
    if (halo) {
      halo.style.opacity = (0.7 * (1 - progress)).toString();
    }
    if (dockShadow) {
      dockShadow.style.opacity = (progress * 0.8).toString();
    }
  }

  window.addEventListener('scroll', updateDockScroll, { passive: true });
  updateDockScroll();

  // 5. Autoplay videos smoothly
  const videos = document.querySelectorAll('video');
  if ('IntersectionObserver' in window) {
    const videoObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        const v = entry.target;
        if (entry.isIntersecting) {
          v.play().catch(() => {});
        } else {
          v.pause();
        }
      });
    }, { threshold: 0.15 });

    videos.forEach(v => videoObserver.observe(v));
  } else {
    videos.forEach(v => v.play().catch(() => {}));
  }

  // 6. Download Modal
  const downloadModal = document.getElementById('astra-download-modal');
  const downloadTriggers = document.querySelectorAll('[title*="Download Astra"], button.sunrise-cta-pill, [data-download-trigger]');

  function openDownloadModal(e) {
    if (e) e.preventDefault();
    if (downloadModal) {
      downloadModal.classList.remove('hidden');
      downloadModal.classList.add('flex');
      document.body.style.overflow = 'hidden';
    }
  }

  function closeDownloadModal() {
    if (downloadModal) {
      downloadModal.classList.add('hidden');
      downloadModal.classList.remove('flex');
      document.body.style.overflow = '';
    }
  }

  downloadTriggers.forEach(btn => {
    btn.addEventListener('click', openDownloadModal);
  });

  if (downloadModal) {
    downloadModal.addEventListener('click', (e) => {
      if (e.target === downloadModal || e.target.closest('[data-modal-close]')) {
        closeDownloadModal();
      }
    });
  }

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeDownloadModal();
  });
});
