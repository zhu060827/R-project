# Synthetic boundary tests are R-only; fixtures are never exported as real archive records.
all_args <- commandArgs(trailingOnly = FALSE)
this_script <- sub("^--file=", "", all_args[grepl("^--file=", all_args)][1])
eda_dir <- normalizePath(file.path(dirname(this_script), ".."), winslash = "/")
.libPaths(c(file.path(eda_dir, ".Rlib"), .libPaths()))
source(file.path(eda_dir, "R", "01_import_clean.R"), encoding = "UTF-8")
results <- list()
test <- function(name, expr) {
  error <- tryCatch({ force(expr); NULL }, error = function(e) conditionMessage(e))
  results[[length(results) + 1L]] <<- tibble(test = name, passed = is.null(error), detail = if (is.null(error)) "ok" else error)
}
test("ID character precision preserved", {
  stopifnot(identical(id_value("7613266934335408171"), "7613266934335408171"), is.na(id_value(7613266934335408171)))
  x <- fromJSON('{"id":7613266934335408171,"id_str":"7613266934335408171"}', simplifyVector = FALSE, bigint_as_char = TRUE)
  stopifnot(identical(x$id_str, "7613266934335408171"))
})
test("timestamp seconds milliseconds Beijing", {
  a <- response_clock(1794520036000); b <- response_clock(1794520036)
  stopifnot(identical(a$bj, "2026-11-13T05:47:16+0800"), identical(a$bj, b$bj), identical(a$utc, "2026-11-12T21:47:16+0000"))
})
test("nested JSON complete multilabel and false", {
  ex <- parse_extra('{"music_tagging":{"Genres":["Pop","Rock"]},"aigc_clip":false}')
  stopifnot(ex$status == "ok", identical(fromJSON(tag_json(ex$value$music_tagging$Genres)), c("Pop", "Rock")), identical(ex$value$aigc_clip, FALSE))
})
test("missing zero and sentinel distinction", {
  stopifnot(is.na(number_check(NULL)$value), identical(number_check(0)$value, 0), is.na(number_check(TRUE)$value), is.na(number_check(-1)$value))
  stopifnot(is.na(tag_json(NULL)), identical(tag_json(list()), "[]"))
})
test("invalid extra and unsafe numeric protection", {
  stopifnot(parse_extra("{bad")$status == "parse_error", number_check("9007199254740993")$issue == "unsafe_double_precision",
            number_check(1.5, TRUE)$issue == "noninteger_count", is.na(number_check("NaN")$value))
})
test("path layouts parsed without imputation", {
  stopifnot(path_date("raw/2026-11-13/hot-music.json") == "2026-11-13", path_date("other/hot-music-2024-01-01.json") == "2024-01-01",
            is.na(path_date("raw/no-date/hot-music.json")))
})
test("corrupt JSON does not abort next file", {
  td <- tempfile("r_fixture_"); dir.create(td)
  bad <- file.path(td, "bad.json"); good <- file.path(td, "good.json")
  writeLines("{bad", bad)
  writeLines('{"status_code":0,"extra":{"now":1794520036000},"music_list":[{"heat":0,"music_info":{"id_str":"7613266934335408171","title":"Test","author":"A","user_count":0,"extra":"{}"}}]}', good)
  r1 <- read_snapshot(bad, "2026-11-12", "bad.json"); r2 <- read_snapshot(good, "2026-11-13", "good.json")
  stopifnot(r1$manifest$parse_status == "invalid", r2$manifest$parse_status == "ok", nrow(r2$observations) == 1)
  unlink(td, recursive = TRUE)
})
test("same ID cross snapshot retained; within snapshot flagged", {
  x <- tibble(snapshot_id = c("a", "a", "b"), douyin_music_id = rep("7613266934335408171", 3)) %>%
    group_by(snapshot_id, douyin_music_id) %>% mutate(duplicate = n() > 1L) %>% ungroup()
  stopifnot(identical(x$duplicate, c(TRUE, TRUE, FALSE)), nrow(x) == 3)
})
test("metadata missing transitions retained", {
  x <- tibble(value = c("old", NA_character_, "new")) %>%
    mutate(changed = row_number() > 1L & coalesce(value, "<NA>") != coalesce(lag(value), "<NA>"))
  stopifnot(identical(x$changed, c(FALSE, TRUE, TRUE)))
})
test("CSV ID tags zero and typed time round trip", {
  file <- tempfile(fileext = ".csv")
  x <- tibble(id = "7613266934335408171", tags = '["Pop","Rock"]', zero = 0, missing = NA_real_,
              time = ymd_hms("2026-11-13 05:47:16", tz = "Asia/Shanghai"))
  write_data(x, file)
  y <- read_csv(file, col_types = cols(.default = col_character()), show_col_types = FALSE)
  stopifnot(y$id == x$id, y$tags == x$tags, y$zero == "0", is.na(y$missing), y$time == "2026-11-13T05:47:16+0800")
  unlink(file)
})
table <- bind_rows(results)
write_data(table, file.path(eda_dir, "reports", "r_unit_tests.csv"))
print(table, n = Inf)
if (!all(table$passed)) stop("R unit tests failed")
