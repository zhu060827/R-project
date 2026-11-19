(function () {
  function init() {
    document.querySelectorAll('[data-page]').forEach(function(button) {
      button.addEventListener('click', function() {
        var features = button.dataset.page === 'features', dynamics = button.dataset.page === 'dynamics', compare = button.dataset.page === 'compare';
        document.getElementById('page1_view').hidden = features || dynamics || compare;
        document.getElementById('page2_view').hidden = !features;
        document.getElementById('page3_view').hidden = !dynamics;
        document.getElementById('page4_view').hidden = !compare;
        document.querySelector('.app-shell').classList.toggle('is-features', features);
        document.querySelector('.app-shell').classList.toggle('is-dynamics', dynamics);
        document.querySelector('.app-shell').classList.toggle('is-compare', compare);
        var caption = document.querySelector('.brand small');
        if (!caption.dataset.original) caption.dataset.original = caption.textContent;
        caption.textContent = compare ? 'CHINA · UNITED STATES' : caption.dataset.original;
        document.querySelectorAll('[data-page]').forEach(function(nav) {
          var active = nav === button; nav.classList.toggle('active', active);
          if(active) nav.setAttribute('aria-current', 'page'); else nav.removeAttribute('aria-current');
        });
        // Notify Shiny after showing its outputs, then resize visible Plotly widgets.
        if(window.jQuery) jQuery(compare ? '#page4_view' : dynamics ? '#page3_view' : features ? '#page2_view' : '#page1_view').trigger('shown');
        window.dispatchEvent(new Event('resize'));
      });
    });
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
