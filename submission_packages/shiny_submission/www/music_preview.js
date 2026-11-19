(function () {
  'use strict';
  function preparePreview(event) {
    var root = event.target;
    if (!root.matches('.mp-preview-modal')) return;
    root.querySelectorAll('audio[data-local-preview-src]').forEach(function (audio) {
      if (audio._mpLoading || audio._mpClosed) return;
      // This httpuv build does not serve byte ranges. Fetch the small local MP3
      // once into a Blob so native controls can seek reliably without a new server.
      audio._mpLoading = true;
      audio._mpAbort = new AbortController();
      fetch(audio.dataset.localPreviewSrc, {signal: audio._mpAbort.signal, credentials: 'same-origin'})
        .then(function (response) { if (!response.ok) throw new Error('Audio HTTP ' + response.status); return response.blob(); })
        .then(function (blob) {
          if (!audio.isConnected || audio._mpClosed) return;
          audio._mpObjectURL = URL.createObjectURL(blob);
          audio.src = audio._mpObjectURL;
          audio.load();
        }).catch(function (error) {
          if (error.name !== 'AbortError') console.error('MusicPulse preview:', error.message);
        });
    });
  }
  function stopPreview(root) {
    root = root || document.querySelector('.mp-preview-modal');
    if (!root) return;
    root.querySelectorAll('audio').forEach(function (audio) {
      audio._mpClosed = true;
      if (audio._mpAbort) audio._mpAbort.abort();
      audio.pause();
      audio.removeAttribute('src');
      audio.querySelectorAll('source').forEach(function (source) { source.removeAttribute('src'); });
      audio.load();
      if (audio._mpObjectURL) { URL.revokeObjectURL(audio._mpObjectURL); audio._mpObjectURL = null; }
    });
    root.querySelectorAll('iframe').forEach(function (frame) { frame.src = 'about:blank'; });
  }
  function closed(event) {
    if (!event.target.matches('.mp-preview-modal')) return;
    stopPreview(event.target);
    if (window.Shiny) Shiny.setInputValue('mp_preview_closed', Date.now(), {priority: 'event'});
  }
  document.addEventListener('hide.bs.modal', closed);
  document.addEventListener('hidden.bs.modal', closed);
  document.addEventListener('shown.bs.modal', preparePreview);
  // Native audio controls can consume Escape before Bootstrap's bubbling
  // handler sees it. Capture Escape only while this preview modal is visible.
  document.addEventListener('keydown', function (event) {
    if (event.key !== 'Escape' && event.code !== 'Escape' && event.keyCode !== 27) return;
    var root = document.querySelector('.mp-preview-modal.show');
    if (!root) return;
    var closeButton = root.querySelector('.mp-preview-x');
    if (closeButton) { event.preventDefault(); event.stopPropagation(); closeButton.click(); }
  }, true);
  document.addEventListener('play', function (event) {
    if (!event.target.matches('.mp-preview-modal audio')) return;
    document.querySelectorAll('.mp-preview-modal audio').forEach(function (other) {
      if (other !== event.target) other.pause();
    });
  }, true);
  // External navigation is a distinct target; it must never act as a row or Plotly selection.
  document.addEventListener('click', function (event) {
    if (event.target.closest('.mp-kugou-link')) event.stopPropagation();
  }, true);
  window.addEventListener('pagehide', function () { stopPreview(); });
  function bind() {
    if (!window.Shiny || !window.jQuery) return;
    Shiny.addCustomMessageHandler('mpStopPreview', function () { stopPreview(); });
    window.jQuery(document).on('hide.bs.modal hidden.bs.modal', '.mp-preview-modal', closed);
    window.jQuery(document).on('shown.bs.modal', '.mp-preview-modal', preparePreview);
    window.jQuery(document).on('shiny:disconnected', function () { stopPreview(); });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', bind);
  else bind();
})();
