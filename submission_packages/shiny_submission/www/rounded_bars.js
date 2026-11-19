(function () {
  'use strict';
  // Reuse only the teammate's SVG corner treatment. Preserve data, exact bounds,
  // original colours, Hover and clicks; do not enlarge small bars or add effects.
  var chartIds = ['feature_genre_plot', 'duration_douyin', 'duration_kugou', 'cmp_diverging'];
  function roundBars(plot) {
    if (!plot) return;
    plot.querySelectorAll('.barlayer .point path').forEach(function (path) {
      var box;
      try { box = path.getBBox(); } catch (error) { return; }
      var x = box.x, y = box.y, w = box.width, h = box.height;
      var radius = Math.min(plot.id === 'cmp_diverging' ? h / 2 : 8, w / 2, h / 2);
      if (!isFinite(radius) || radius <= 0) return;
      var rounded = [
        'M', x + radius, ',', y, 'H', x + w - radius,
        'Q', x + w, ',', y, ' ', x + w, ',', y + radius,
        'V', y + h - radius, 'Q', x + w, ',', y + h, ' ', x + w - radius, ',', y + h,
        'H', x + radius, 'Q', x, ',', y + h, ' ', x, ',', y + h - radius,
        'V', y + radius, 'Q', x, ',', y, ' ', x + radius, ',', y, 'Z'
      ].join('');
      if (path.getAttribute('d') !== rounded) path.setAttribute('d', rounded);
    });
  }
  var queued = false;
  function scan() {
    if (queued) return;
    queued = true;
    window.requestAnimationFrame(function () {
      queued = false;
      chartIds.forEach(function (id) {
        var plot = document.getElementById(id);
        roundBars(plot);
        if (plot && typeof plot.on === 'function' && !plot.musicpulseRoundBound) {
          plot.musicpulseRoundBound = true;
          plot.on('plotly_afterplot', function () { roundBars(plot); });
        }
      });
    });
  }
  function init() {
    new MutationObserver(scan).observe(document.body, {
      childList: true, subtree: true, attributes: true, attributeFilter: ['d']
    });
    window.addEventListener('resize', scan);
    if (window.jQuery) jQuery(document).on('shiny:value', scan);
    scan();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
