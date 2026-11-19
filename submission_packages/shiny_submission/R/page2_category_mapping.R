# Team mapping transcribed from the attachment and the user's follow-up; no inferred additions.
page2_team_mapping <- function() {
  genre <- c(
    'Pop'='Pop','Chinese Pop'='Pop','Cantopop'='Pop','Indie Pop'='Pop','City Pop'='Pop',
    'K-Pop'='Pop','J-Pop'='Pop','Teen Pop'='Pop','Folk Pop'='Pop',
    'Pop Rock'='Rock','Rock'='Rock','Indie Rock'='Rock',
    'R&B/Soul'='R&B / Soul','Contemporary R&B'='R&B / Soul',
    'R&B Rap'='Hip Hop / Rap','Hip Hop/Rap'='Hip Hop / Rap','Trap Rap'='Hip Hop / Rap','Alternative Hip Hop'='Hip Hop / Rap',
    'Dance Pop'='Dance / Electronic','DJ'='Dance / Electronic','Electronic'='Dance / Electronic','EDM'='Dance / Electronic',
    'EDM Trap'='Dance / Electronic','Techno'='Dance / Electronic','Tropical House'='Dance / Electronic',
    'Chinoiserie Electronic'='Dance / Electronic','Chill Beats'='Dance / Electronic',
    'Easy Listening'='Other','Chinese Style'='Other','China-Wave'='Other','Folk'='Other','Chinese Folk'='Other',
    'Classical'='Other','Jazz'='Other','Latin'='Other','Devotional'='Other','Funk'='Other','BGM'='Other',
    'Childhood'='Other','Holiday Music'='Other','Others'='Other')
  mood <- c(Dynamic='Energetic / Positive',Happy='Energetic / Positive',Excited='Energetic / Positive',Inspirational='Energetic / Positive',
    Chill='Calm / Healing',Calm='Calm / Healing',Healing='Calm / Healing',
    Romantic='Romantic / Affectionate',Miss='Romantic / Affectionate',Sweet='Romantic / Affectionate',
    Sorrow='Sad / Lonely',Lonely='Sad / Lonely',Memory='Nostalgic / Reflective',Funny='Playful / Fun',Cute='Playful / Fun')
  list(genre_map=genre,genre_order=c('Pop','Dance / Electronic','Rock','R&B / Soul','Hip Hop / Rap','Other'),
    mood_map=mood,mood_order=unique(unname(mood)),status='team_mapping_active_unlisted_tags_unmapped')
}

# Independently curated associations for unified categories, not concatenated fine-label dictionaries.
page2_team_keywords <- function() {
  genre <- list(
    'Pop'=c(melody=5,chorus=5,catchy=4,hook=4,vocal=3,mainstream=3,harmony=3,rhythm=2,bright=2,radio=1),
    'Dance / Electronic'=c(beat=5,synth=5,dance=4,bass=4,rhythm=4,pulse=3,energy=3,club=2,drop=2,texture=1),
    'Rock'=c(guitar=5,drum=5,energy=4,riff=4,band=3,drive=3,distortion=3,rhythm=2,vocal=2,raw=1),
    'R&B / Soul'=c(groove=5,soulful=5,vocal=4,harmony=4,smooth=3,emotion=3,melody=3,rhythm=2,warm=2,intimacy=1),
    'Hip Hop / Rap'=c(flow=5,rhyme=5,rap=4,beat=4,rhythm=4,bass=3,voice=3,groove=2,urban=2,story=1),
    'Other'=c(variety=5,texture=4,atmosphere=4,tradition=3,acoustic=3,background=2,fusion=2,story=2,instrumental=2,ambience=1))
  mood <- list(
    'Energetic / Positive'=c(energy=5,upbeat=5,joy=4,bright=4,drive=4,hope=3,motion=3,lively=2,cheerful=2,resolve=1),
    'Calm / Healing'=c(calm=5,peaceful=5,soothing=4,gentle=4,relaxed=4,comfort=3,mellow=3,quiet=2,soft=2,balance=1),
    'Romantic / Affectionate'=c(affection=5,tender=5,intimacy=4,longing=4,warm=4,love=3,sweet=3,connection=2,delicate=2,closeness=1),
    'Sad / Lonely'=c(sadness=5,solitude=5,melancholy=4,distance=4,reflection=4,loss=3,quiet=3,longing=2,fragile=2,heartache=1),
    'Nostalgic / Reflective'=c(memory=5,reflection=5,nostalgia=4,time=4,past=4,story=3,echo=3,remembering=2,distance=2,return=1),
    'Playful / Fun'=c(playful=5,fun=5,humour=4,comic=4,light=4,cheerful=3,witty=3,quirky=2,bounce=2,smile=1))
  make <- function(x,attribute) dplyr::bind_rows(lapply(names(x),function(label) {
    weights<-x[[label]]
    dplyr::tibble(attribute=attribute,label=label,keyword=names(weights),base_weight=unname(weights),
      origin='researcher_defined_unified_label_association_not_lyric_frequency')
  }))
  dplyr::bind_rows(make(genre,'Genre'),make(mood,'Mood'))
}
