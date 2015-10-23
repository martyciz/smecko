source("database_helper.R")

VISITS_SQL = 
  "SELECT happened_at
FROM visits
JOIN live_articles ON live_articles.id = visits.sme_id
WHERE live_articles.id = 5060790
AND visits.happened_at BETWEEN live_articles.published_at AND DATE_ADD(live_articles.published_at, INTERVAL 1 DAY)
ORDER BY happened_at"

data <- retrieve_data(VISITS_SQL)

doc.vec <- as.vector(data$happened_at)
doc.vec <- as.POSIXct(doc.vec, format="%Y-%m-%d %H:%M:%S")

hist(doc.vec, breaks = "hours")