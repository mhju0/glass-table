
const dlg = document.getElementById('detail'), row = dlg.querySelector('.frames-row'), info = dlg.querySelector('.info');
let current = null, priorFocus = null;
function show(card) {
  priorFocus = document.activeElement;
  current = card;
  const thumb = card.querySelector('button.shot img').src;
  row.replaceChildren(...JSON.parse(card.dataset.frames).map((src, i) => {
    const img = new Image(); img.alt = ''; img.src = src;
    img.onerror = () => { if (i === 0) img.src = thumb; else img.remove(); };
    return img;
  }));
  info.replaceChildren(card.querySelector('template').content.cloneNode(true));
  const flow = card.closest('.flow');
  dlg.querySelector('.where').textContent = (flow ? flow.querySelector('h3').textContent + ' · ' : '') + '#' + card.id;
  dlg.classList.add('open'); dlg.scrollTop = 0; row.scrollLeft = 0;
  document.body.style.overflow = 'hidden'; dlg.querySelector('[data-close]').focus();
}
function step(d) {
  if (!current) return;
  const cards = [...current.closest('.track').querySelectorAll('.card')];
  const next = cards[cards.indexOf(current) + d];
  if (next) { show(next); next.scrollIntoView({block:'nearest', inline:'center'}); }
}
function close() { dlg.classList.remove('open'); document.body.style.overflow = ''; if (priorFocus && priorFocus.isConnected) priorFocus.focus(); else if (current) current.querySelector('button.shot').focus(); }
document.addEventListener('click', e => {
  const b = e.target.closest('button.shot'); if (b) { show(b.closest('.card')); return; }
  const g = e.target.closest('[data-go]'); if (g) { step(+g.dataset.go); return; }
  if (e.target.closest('[data-close]') || e.target === dlg) close();
});
document.addEventListener('keydown', e => {
  if (!dlg.classList.contains('open')) return;
  if (e.key === 'Escape') close(); else if (e.key === 'ArrowRight') step(1); else if (e.key === 'ArrowLeft') step(-1);
});
document.getElementById('onlyFlagged').addEventListener('change', e => document.body.classList.toggle('only-flagged', e.target.checked));
document.getElementById('theme').addEventListener('click', () => {
  const r = document.documentElement; const dark = r.dataset.theme ? r.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  r.dataset.theme = dark ? 'light' : 'dark';
});


(() => {
  const dlg = document.getElementById('detail');
  dlg.addEventListener('keydown', (event) => {
    if (event.key !== 'Tab') return;
    const controls = [...dlg.querySelectorAll('button')].filter(button => !button.disabled);
    if (!controls.length) return;
    const first = controls[0], last = controls[controls.length - 1];
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault(); last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault(); first.focus();
    }
  });
  document.querySelectorAll('nav a[href^="#"], .finding a[href^="#"], .flaggroup a[href^="#"]')
    .forEach(link => link.addEventListener('click', () => {
      const target = document.getElementById(decodeURIComponent(link.hash.slice(1)));
      if (target && target.classList.contains('card')) {
        requestAnimationFrame(() => target.scrollIntoView({block:'center', inline:'center'}));
      }
    }));
})();
