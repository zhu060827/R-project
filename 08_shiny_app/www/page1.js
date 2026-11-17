(function () {
  'use strict';
  var pendingId = null;
  var selectedId = null;
  function markSelection() {
    document.querySelectorAll('.song-row').forEach(function (row) {
      var active = row.dataset.candidateId === selectedId;
      row.classList.toggle('is-selected', active);
      row.setAttribute('aria-pressed', active ? 'true' : 'false');
    });
  }
  function locatePending() {
    if (!pendingId) return;
    var list = document.getElementById('song_list_scroll');
    var row = document.querySelector('.song-row[data-candidate-id="' + CSS.escape(pendingId) + '"]');
    if (!list || !row) return;
    var rowRect = row.getBoundingClientRect();
    var listRect = list.getBoundingClientRect();
    // Change this container's scroll offset only; never scroll the document.
    list.scrollTop += rowRect.top - listRect.top - (list.clientHeight - rowRect.height) / 2;
    row.focus({preventScroll: true});
    pendingId = null;
  }
  function init() {
    if (!window.Shiny) { window.setTimeout(init, 50); return; }
    Shiny.addCustomMessageHandler('currentCandidate', function (message) {
      selectedId = message.id; markSelection();
    });
    Shiny.addCustomMessageHandler('focusCandidate', function (message) {
      selectedId = message.id; pendingId = message.id; markSelection();
      window.requestAnimationFrame(locatePending);
    });
    document.addEventListener('click', function (event) {
      var row = event.target.closest('.song-row');
      if (!row) return;
      selectedId = row.dataset.candidateId; markSelection();
      Shiny.setInputValue('explorer_select', selectedId, {priority: 'event'});
    });
    var list = document.getElementById('explorer_rows');
    if (list) new MutationObserver(function () { markSelection(); locatePending(); }).observe(list, {childList: true, subtree: true});
    var resizeTimer;
    window.addEventListener('resize', function () {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(function () {
        document.querySelectorAll('.js-plotly-plot').forEach(function (el) { if(window.Plotly && el.getClientRects().length) Plotly.Plots.resize(el); });
      }, 100);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
