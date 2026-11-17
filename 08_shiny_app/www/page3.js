(function(){
  var tip;
  function hide(){if(tip)tip.hidden=true;}
  function show(button){
    if(!tip){tip=document.createElement('div');tip.id='dyn_month_tooltip';tip.className='dyn-month-tooltip';tip.setAttribute('role','tooltip');document.body.appendChild(tip);}
    tip.innerHTML=button.dataset.dynTooltip;tip.hidden=false;
    var r=button.getBoundingClientRect(),t=tip.getBoundingClientRect();
    tip.style.left=Math.max(8,Math.min(r.right+10,innerWidth-t.width-8))+'px';
    tip.style.top=Math.max(8,Math.min(r.top-20,innerHeight-t.height-8))+'px';
  }
  document.addEventListener('mouseover',function(e){var b=e.target.closest('.dyn-month-block');if(b)show(b);});
  document.addEventListener('mouseout',function(e){if(e.target.closest('.dyn-month-block'))hide();});
  document.addEventListener('focusin',function(e){var b=e.target.closest('.dyn-month-block');if(b)show(b);});
  document.addEventListener('focusout',hide);
  document.addEventListener('click',function(e){
    var b=e.target.closest('[data-dyn-song]');hide();
    if(b&&b.dataset.dynSong&&window.Shiny)Shiny.setInputValue('dyn_select',{id:b.dataset.dynSong,month:b.dataset.dynMonth||null,origin:'C',nonce:performance.now()},{priority:'event'});
  });
})();
