# for reproducibility
set.seed(0)

# create a corpus
docs <- tm::Corpus(tm::VectorSource(data.to.cloud))
docs <- tm::tm_map(docs, tm::content_transformer(tolower))
if (clean.text == TRUE) {
  # cleaning text
  docs <- tm::tm_map(docs, tm::removeWords, tm::stopwords("portuguese"))
  docs <- tm::tm_map(docs, tm::removeWords, tm::stopwords("english"))
  docs <- tm::tm_map(docs, tm::removePunctuation)
  docs <- tm::tm_map(docs, tm::removeNumbers)
  docs <- tm::tm_map(docs, tm::stripWhitespace)
  # create a document-term matrix
  dtm <- tm::TermDocumentMatrix(docs)
  matrix <- as.matrix(dtm)
  words <- sort(rowSums(matrix), decreasing = TRUE)
  df <- data.frame(word = names(words), freq = words)
  # set minimum word frequency
  df <- df[df$freq >= 1, ]
} else {
  # count the frequency of each term
  words <- sort(table(tolower(data.to.cloud)), decreasing = TRUE)
  df <- data.frame(word = names(words), freq = as.numeric(words))
  rownames(df) <- names(words)
  # replace frequencies by rank order
  df$freq <- rank(df$freq, ties.method = "first")
}

# set plot area
par(
  oma = c(0, 0, 0, 0),
  mar = c(0, 0, 0, 0),
  bg = main.color,
  col.lab = "white",
  col.axis = "white",
  fg = "white",
  col.main = "white"
)
# generate word cloud
if (length(df) != 0) {
  wordcloud <- wordcloud2::wordcloud2(
    data = df,
    size = 0.5,
    color = rep(
      RColorBrewer::brewer.pal(n = 9, name = "Set3"),
      length.out = length(df$freq)
    ),
    backgroundColor = main.color,
    shuffle = FALSE,
    rotateRatio = 0,
    ellipticity = 0.5
  ) %>%
    htmlwidgets::prependContent(
      htmltools::tags$h1(style = "position:absolute; left:50%; transform:translateX(-50%); background-color:main.color; font-size:40px; color:white; line-height:normal;", cloud.title)
    ) %>%
    htmlwidgets::prependContent(
      htmltools::tags$body(style = "font-family:'Lato','Helvetica Neue',Helvetica, Arial,sans-serif; background-color:main.color; margin:0; padding:0;")
    )
  # save it in html
  htmlwidgets::saveWidget(wordcloud, file.path(dir.path, "tmp.html"), selfcontained = F)
  
  # deactivate the crash reporter
  old_chrome_args <- chromote::get_chrome_args()
  chromote::set_chrome_args("--disable-crash-reporter")
  Sys.setenv(CHROMOTE_CHROME = chromote::find_chrome())
  
  # and in png
  webshot2::webshot(
    url = file.path("file:///", dir.path, "tmp.html"),
    file = file.path(dir.path, paste0(sheet, ".png")),
    delay = 5,
    vwidth = round(1344 * 0.7),
    vheight = round(960 * 0.7)
  )
  # delete the tmp folder and file
  unlink(file.path(dir.path, "tmp_files"), recursive = TRUE)
  unlink(file.path(dir.path, "tmp.html"))
  
  # Restore old defaults
  chromote::set_chrome_args(old_chrome_args)
} else {
  source("Scripts/plot-margins.R", local = knitr::knit_global())
  # plot area setup
  par(mar = c(1.5, 15, 1, 1))
  
  layout.m <- c(1)
  png(file.path(dir.path, paste0(sheet, ".png")), width = round(1344 * 0.7), height = round(960 * 0.7))
  source("Scripts/plot-margins.R", local = knitr::knit_global())
  plot(0, type = 'n', axes = FALSE)
  title(
    main = sheet,
    outer = TRUE,
    cex.main = 3
  )
  dev.off()
}
