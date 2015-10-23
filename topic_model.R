library(topicmodels)
library(RTextTools)
library(tm)
source("database_helper.R")

LEMATIZED_SQL = 
"SELECT body_lematized
FROM live_articles
WHERE body_lematized != ''"

data <- retrieve_data(LEMATIZED_SQL)
dtm <- create_matrix(as.vector(data$body_lematized), weighting=weightTf)
k <- 10

lda <- LDA(matrix, k)

terms(lda)
topics(lda)

#todo visualize using LDAvis

