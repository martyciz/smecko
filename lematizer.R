library(httr)
library(tm)

UNLEMATIZED_SQL = 
"SELECT body_no_html,id
FROM live_articles
WHERE body_lematized = ''
LIMIT 1"

data <- retrieve_data(UNLEMATIZED_SQL)

doc.id = data$id
doc.vec <- VectorSource(data$body_no_html)
doc.corpus <- Corpus(doc.vec)

stopwords <- readLines("slovak_stopwords.txt", encoding='UTF-8')

# PRE-PROCESS

doc.corpus <- tm_map(doc.corpus, removePunctuation, lazy=TRUE) 
doc.corpus <- tm_map(doc.corpus, stripWhitespace, lazy=TRUE)
for(i in seq(doc.corpus)) {
  doc.corpus[[i]] <- gsub("/", " ", doc.corpus[[i]])   
  doc.corpus[[i]] <- gsub("@", " ", doc.corpus[[i]])
  doc.corpus[[i]] <- gsub("\\|", " ", doc.corpus[[i]])
}
doc.corpus <- tm_map(doc.corpus, removeNumbers, lazy=TRUE)
doc.corpus <- tm_map(doc.corpus, tolower, lazy=TRUE)
doc.corpus <- tm_map(doc.corpus, removeWords,stopwords, lazy=TRUE)

# LEMATIZE AND SAVE

for (i in seq(doc.corpus)) {
  
  if (doc.corpus[[i]] == "") {
    next
  }
  lem_result <- POST("http://text.fiit.stuba.sk:8080/lematizer/services/lemmatizer/lemmatize/fast",
            body = doc.corpus[[i]],
            content_type('text/plain'),
            add_headers(tools = "all",disam="true")
  )
  
  print(lem_result$status)
  if (lem_result$status == 200) {
    text <- httr::content(lem_result, encoding='UTF-8')
    
    
    id <- doc.id[i]
    if (!is.null(text)) {
      query <- sprintf("UPDATE live_articles SET body_lematized = '%s' WHERE id= %d", text, id)
      dbGetQuery(mydb, query)
    }
  }
}

# REMOVE STOPWORDS

LEMATIZED_SQL = 
  "SELECT id, body_lematized
FROM live_articles
WHERE body_lematized != ''"

db_config <- yaml.load_file("db_config.yml")
mydb = dbConnect(MySQL(), host=db_config$db$host, dbname=db_config$db$name, user=db_config$db$user, password=db_config$db$pass, CharSet='utf8')
dbGetQuery(mydb, "SET NAMES 'utf8'")

rs <- dbSendQuery(mydb, LEMATIZED_SQL)
data <- fetch(rs, n=-1)
stopwords <- readLines("slovak_stopwords.txt",encoding='UTF-8')

doc.id = data$id
doc.vec <- VectorSource(data$body_lematized)
doc.corpus <- Corpus(doc.vec)

doc.corpus <- tm_map(doc.corpus, removeWords,stopwords, lazy=TRUE)

for (i in seq(doc.corpus)) {
  id <- doc.id[i]
  text <- doc.corpus[[i]]

  if (!is.null(text)) {
    print(id)
    query <- sprintf("UPDATE live_articles SET body_lematized = '%s' WHERE id= %d", text, id)
    dbGetQuery(mydb, query)
  }
}
