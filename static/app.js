/* SmartFix – app.js  (Phase 1 frontend polish, no dependencies) */
'use strict';

/* ── Hamburger nav ── */
function initHamburger() {
  const btn = document.getElementById('hamburger-btn');
  const drawer = document.getElementById('mobile-nav');
  if (!btn || !drawer) return;
  btn.addEventListener('click', () => {
    const open = drawer.classList.toggle('open');
    btn.classList.toggle('open', open);
    btn.setAttribute('aria-expanded', open);
  });
  /* Close on outside click */
  document.addEventListener('click', e => {
    if (!btn.contains(e.target) && !drawer.contains(e.target)) {
      drawer.classList.remove('open');
      btn.classList.remove('open');
    }
  });
}

/* ── Submit-button loading state ── */
function initLoadingButtons() {
  document.querySelectorAll('form').forEach(form => {
    form.addEventListener('submit', function (e) {
      /* Skip forms that use onsubmit confirm and were cancelled */
      const submit = form.querySelector('button[type=submit], button:not([type=button])');
      if (!submit || submit.classList.contains('no-load')) return;
      /* Small delay so confirm() dialogs still work */
      setTimeout(() => {
        submit.disabled = true;
        submit.dataset.original = submit.textContent;
        submit.textContent = 'Please wait…';
        submit.classList.add('btn-loading');
      }, 50);
    });
  });
}

/* ── Home page: live search + sort ── */
function initHomeSearch() {
  const searchInput = document.getElementById('worker-search');
  const grid        = document.getElementById('worker-grid');
  if (!searchInput || !grid) return;

  const cards = () => Array.from(grid.querySelectorAll('.wcard[data-name]'));

  /* Filter cards by search text */
  function filter() {
    const q = searchInput.value.trim().toLowerCase();
    cards().forEach(card => {
      const name = (card.dataset.name || '').toLowerCase();
      card.style.display = (!q || name.includes(q)) ? '' : 'none';
    });
    /* Show/hide empty state */
    const visible = cards().filter(c => c.style.display !== 'none');
    const es = document.getElementById('worker-empty');
    if (es) es.style.display = visible.length ? 'none' : 'block';
  }

  /* Sort cards by a numeric data attribute */
  function sort(key) {
    const sorted = cards().sort((a, b) => {
      const av = parseFloat(a.dataset[key]) || 0;
      const bv = parseFloat(b.dataset[key]) || 0;
      return bv - av; /* descending */
    });
    sorted.forEach(c => grid.appendChild(c));
    filter(); /* re-apply filter after sort */
  }

  searchInput.addEventListener('input', filter);

  /* Sort chips */
  document.querySelectorAll('.sort-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.sort-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      sort(chip.dataset.sort);
    });
  });
}

/* ── Star picker (review page) ── */
function initStarPicker() {
  const picker = document.getElementById('star-picker');
  if (!picker) return;
  const stars  = picker.querySelectorAll('.sp-star');
  const hint   = document.getElementById('star-hint');
  const labels = ['', '1 star – Very poor', '2 stars – Poor', '3 stars – Average',
                  '4 stars – Good', '5 stars – Excellent'];

  function paint(n) {
    stars.forEach((s, i) => s.classList.toggle('on', i < n));
    if (hint) hint.textContent = labels[n] || '';
  }

  /* Read currently-checked radio to initialise */
  const checked = picker.querySelector('input[name=rating]:checked');
  paint(checked ? +checked.value : 5);

  stars.forEach((s, i) => {
    s.addEventListener('click',     () => paint(i + 1));
    s.addEventListener('mouseover', () => paint(i + 1));
  });
  picker.addEventListener('mouseleave', () => {
    const c = picker.querySelector('input[name=rating]:checked');
    paint(c ? +c.value : 5);
  });
}

/* ── Boot ── */
document.addEventListener('DOMContentLoaded', () => {
  initHamburger();
  initLoadingButtons();
  initHomeSearch();
  initStarPicker();
});
