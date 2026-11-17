(function () {
  function init() {
    document.querySelectorAll('[data-page]').forEach(function(button) {
      button.addEventListener('click', function() {
        var features = button.dataset.page === 'features';
        document.getElementById('page1_view').hidden = features;
        document.getElementById('page2_view').hidden = !features;
        document.querySelector('.app-shell').classList.toggle('is-features', features);
        document.querySelectorAll('[data-page]').forEach(function(nav) {
          var active = nav === button; nav.classList.toggle('active', active);
          if(active) nav.setAttribute('aria-current', 'page'); else nav.removeAttribute('aria-current');
        });
        // Notify Shiny after showing its outputs, then resize visible Plotly widgets.
        if(window.jQuery) jQuery(features ? '#page2_view' : '#page1_view').trigger('shown');
        window.dispatchEvent(new Event('resize'));
      });
    });
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
