(function () {
  function bind() {
    if (!window.Shiny) return;
    Shiny.addCustomMessageHandler('musicpulse-compare-state', function (state) {
      window.musicpulseCompareState = state;
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', bind); else bind();
})();
