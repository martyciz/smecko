library(yaml)
library(RMySQL)

retrieve_data <- function(sql) {
  db_config <- yaml.load_file("db_config.yml")
  mydb <- dbConnect(MySQL(),
                   host=db_config$db$host,
                   dbname=db_config$db$name,
                   user=db_config$db$user,
                   password=db_config$db$pass,
                   CharSet='utf8')

  dbGetQuery(mydb, "SET NAMES 'utf8'")
  rs <- dbSendQuery(mydb, sql)
  data <- fetch(rs, n=-1)
  
  dbDisconnect(mydb)

  return(data)
}