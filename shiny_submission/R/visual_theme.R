# Presentation roles only. Keep platform, country, direction and co-observation
# palettes separate: identical old colours did not imply identical semantics.
mp_theme <- list(
  ink='#442158', muted='#705F7D', purple='#9475BE', pink='#D99BC9', gold='#F2C987',
  cream='#FAF7FC', border='#EAE3EF', grid='#EFEAF3', selected='#59316F',
  platform=c(Douyin='#9475BE',Kugou='#F2C987',TikTok='#65447E',Spotify='#C56F9B'),
  country=c(China='#8767B2','United States'='#C983A5'),
  direction=c('Short-video first'='#BA8BB5','Streaming first'='#D6AE6F','Same day'='#D7D1DD'),
  coobserved=c(yes='#A18ABB',no='#E8C483'),
  cloud=c('#9475BE','#D18CB8','#C69C61','#AF77B1','#775398','#D7AC72','#B9789C','#8C73AE'))

mp_theme_css <- function() {
  htmltools::HTML(sprintf(':root { --ink:%s; --muted:%s; --blue:%s; --teal:%s; --neutral:%s; --border:%s; --mp-purple:%s; --mp-pink:%s; --mp-gold:%s; --mp-cream:%s; --mp-selected:%s; --mp-grid:%s; --mp-coobserved:%s; --mp-not-coobserved:%s; --mp-kugou-ink:#89612B; }',
    mp_theme$ink,mp_theme$muted,mp_theme$purple,mp_theme$gold,mp_theme$gold,mp_theme$border,
    mp_theme$purple,mp_theme$pink,mp_theme$gold,mp_theme$cream,mp_theme$selected,mp_theme$grid,
    mp_theme$coobserved[['yes']],mp_theme$coobserved[['no']] ))
}

mp_icon <- function(name) {
  paths <- switch(name,
    wave='<path d="M3 11v2m4-7v12m5-16v20m5-16v12m4-7v2"/>',
    music='<path d="M9 18V6l11-3v12M9 6l11-3"/><ellipse cx="5.5" cy="18" rx="3.5" ry="2.5"/><ellipse cx="16.5" cy="15" rx="3.5" ry="2.5"/>',
    shared='<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5.5"/><circle cx="12" cy="12" r="1.5"/>',
    calendar='<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M7 3v4m10-4v4M3 10h18"/>')
  htmltools::HTML(paste0('<svg class="mp-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">',paths,'</svg>'))
}
