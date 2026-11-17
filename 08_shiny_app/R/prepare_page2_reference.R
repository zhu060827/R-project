args <- commandArgs(FALSE)
script <- sub('^--file=', '', args[grepl('^--file=', args)][1])
app_dir <- normalizePath(file.path(dirname(script), '..'), winslash = '/')
source(file.path(app_dir, 'R/data_loader.R'), encoding = 'UTF-8'); project <- configure_musicpulse(app_dir)
suppressPackageStartupMessages({library(dplyr);library(tidyr)})
source(file.path(app_dir, 'R/page2_data.R'), encoding = 'UTF-8')
data <- load_page2_data(project, app_dir, references = FALSE)
dir.create(file.path(app_dir, 'data'), showWarnings = FALSE)
alignment <- data$inventory %>% mutate(display_label = source_label, alignment_rule = 'exact_spelling_only_no_semantic_merging',
  provenance = if_else(platform == 'Douyin', 'source_platform_multilabel', 'supplier_rule_based_screening_review_pending'))
readr::write_excel_csv(alignment, file.path(app_dir, 'data/page2_label_alignment.csv'))
genre <- list(
 'Alternative Hip Hop'=c('experimental','beats','flow'), BGM=c('background','scene','ambience'), Cantopop=c('Cantonese','melody','pop'),
 Childhood=c('nostalgia','playful','memories'), 'Chill Beats'=c('mellow','beats','relaxed'), 'China-Wave'=c('fusion','Chinese','modern'),
 'Chinese Folk'=c('acoustic','tradition','storytelling'), 'Chinese Pop'=c('Mandarin','melody','chorus'), 'Chinese Style'=c('tradition','heritage','melody'),
 'Chinoiserie Electronic'=c('fusion','synth','Chinese'), 'City Pop'=c('urban','groove','retro'), Classical=c('orchestral','acoustic','composition'),
 'Contemporary R&B'=c('soulful','groove','vocals'), 'Dance Pop'=c('rhythmic','catchy','dance'), Devotional=c('reflective','faith','calm'),
 DJ=c('mixing','beat','club'), 'Easy Listening'=c('mellow','smooth','background'), EDM=c('drop','synth','dance'), 'EDM Trap'=c('bass','drop','beats'),
 Electronic=c('synth','texture','pulse'), Folk=c('acoustic','storytelling','roots'), 'Folk Pop'=c('acoustic','catchy','melody'),
 Funk=c('groove','bass','rhythm'), 'Hip Hop/Rap'=c('rhythm','flow','rap'), 'Holiday Music'=c('festive','celebration','seasonal'),
 'Indie Pop'=c('melodic','independent','texture'), 'Indie Rock'=c('guitars','independent','energy'), 'J-Pop'=c('Japanese','melody','pop'),
 Jazz=c('improvisation','swing','harmony'), 'K-Pop'=c('Korean','dance','chorus'), Latin=c('rhythm','percussion','dance'),
 Others=c('varied','unclassified','diverse'), Pop=c('melody','catchy','chorus','mainstream'), 'Pop Rock'=c('guitars','catchy','energy'),
 'R&B Rap'=c('soulful','flow','beats'), 'R&B/Soul'=c('groove','soulful','vocals'), Rock=c('guitars','drums','energy'),
 Techno=c('pulse','repetition','synth'), 'Teen Pop'=c('catchy','youthful','chorus'), 'Trap Rap'=c('bass','flow','beats'),
 'Tropical House'=c('sunny','percussion','groove'))
mood <- list(Calm=c('peaceful','quiet','still'),Chill=c('relaxed','mellow','easygoing'),Cute=c('playful','light','sweet'),
 Dynamic=c('energetic','motion','drive'),Excited=c('thrilling','lively','energy'),Funny=c('playful','humour','comic'),
 Happy=c('cheerful','upbeat','bright','joyful'),Healing=c('soothing','comfort','gentle'),Inspirational=c('hope','uplift','resolve'),
 Lonely=c('solitude','reflection','distance'),Memory=c('nostalgia','remember','reflection'),Miss=c('longing','distance','reflection'),
 Romantic=c('affection','intimate','tender'),Sorrow=c('melancholy','sadness','reflection'),Sweet=c('tender','warm','delicate'))
stopifnot(setequal(names(genre), data$genres), setequal(names(mood), data$moods))
make_words <- function(x, attribute) dplyr::bind_rows(lapply(names(x), function(label) {
  keywords <- x[[label]]; weights <- c(3, rep(2, length(keywords) - 1L))
  dplyr::tibble(attribute, label, keyword = keywords, preset_weight = weights,
    origin = 'researcher_defined_label_association_not_lyrics', weight_rule = 'sum_preset_weights_across_selected_labels')
}))
words <- bind_rows(make_words(genre, 'Genre'), make_words(mood, 'Mood'))
readr::write_excel_csv(words, file.path(app_dir, 'data/page2_keyword_dictionary.csv'))
readr::write_excel_csv(tibble(platform = c('Douyin','Kugou'), source_field = c('duration_raw','duration_ms'),
  source_unit = c('unverified','supplier_milliseconds'), minutes_multiplier = c(NA_real_,1/60000),
  display_unit = c('source units (unverified)','min'), policy = c('user_confirmed_keep_unverified_do_not_convert','provided_milliseconds_divided_by_60000')),
  file.path(app_dir, 'data/page2_duration_policy.csv'), na = '\\N')
cat('Prepared', nrow(alignment), 'exact-label provenance rows;', nrow(words), 'editorial keyword links.\n')
