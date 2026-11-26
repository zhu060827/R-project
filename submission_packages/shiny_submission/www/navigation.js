(function () {
  function showPage(page) {
    var features = page === 'features', dynamics = page === 'dynamics', compare = page === 'compare';
    if (window.Shiny) Shiny.setInputValue('active_page', page, {priority: 'event'});
    var page1 = document.getElementById('page1_view');
    var page2 = document.getElementById('page2_view');
    var page3 = document.getElementById('page3_view');
    var page4 = document.getElementById('page4_view');
    if (!page1 || !page2 || !page3 || !page4) return;
    page1.hidden = features || dynamics || compare;
    page2.hidden = !features;
    page3.hidden = !dynamics;
    page4.hidden = !compare;
    var shell = document.querySelector('.app-shell');
    if (shell) {
      shell.classList.toggle('is-features', features);
      shell.classList.toggle('is-dynamics', dynamics);
      shell.classList.toggle('is-compare', compare);
    }
    var caption = document.querySelector('.brand small');
    if (caption) {
      if (!caption.dataset.original) caption.dataset.original = caption.textContent;
      caption.textContent = compare ? 'CHINA · UNITED STATES' : caption.dataset.original;
    }
    document.querySelectorAll('[data-page]').forEach(function(nav) {
      var active = nav.dataset.page === page;
      nav.classList.toggle('active', active);
      if (active) nav.setAttribute('aria-current', 'page'); else nav.removeAttribute('aria-current');
    });
    if (window.jQuery) jQuery(compare ? '#page4_view' : dynamics ? '#page3_view' : features ? '#page2_view' : '#page1_view').trigger('shown');
    window.dispatchEvent(new Event('resize'));
  }

  function init() {
    window.MusicPulseNavigate = showPage;
    // Delegation survives Shiny reconnects and DOM replacement of navigation buttons.
    if (document.documentElement.dataset.mpNavigationBound !== '1') {
      document.documentElement.dataset.mpNavigationBound = '1';
      document.addEventListener('click', function(event) {
        var button = event.target.closest && event.target.closest('[data-page]');
        if (!button) return;
        event.preventDefault();
        showPage(button.dataset.page);
      }, true);
    }
    showPage('overview');
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
