SQLs FOR DATABASE PRE-PROCESSING:

Take only articles published in the 15 days range:

CREATE TABLE live_articles
(
SELECT *
FROM articles
WHERE ( (DATE(published_at) >= '2009-10-07' AND DATE(published_at) < '2009-10-22') )
AND body_no_html != "" AND body_no_html IS NOT NULL
);

To avoid bias in article number of visits (e.g. first article had more time to be visited in 15 days than last article)
we select visits for the first 24 hours:

UPDATE live_articles
JOIN 
(  SELECT sme_id, COUNT(*) as visits_day
	FROM visits
	JOIN live_articles ON visits.sme_id = live_articles.id
	WHERE visits.happened_at BETWEEN live_articles.published_at AND DATE_ADD(live_articles.published_at, INTERVAL 1 DAY)
	GROUP BY sme_id
) AS visits_table ON visits_table.sme_id = live_articles.id
SET live_articles.visits_day = visits_table.visits_day;

(not considered: uniqueness of visit by merging records with same cookie and/or ip and counting it as only one visit)

FILES:

lematizer.R
script to pre-process slovak text - removing special characters, white characters, numbers and stopwords
and lematizing using text.fiit.stuba.sk lematizer.
Should be one-time called script, all pre-processed text is saved as body_lematized in db table.

histograms.R
Simple script to see how visits of article has progressed over time, see visits_over_time_example.png.
For articles there should be high peak of readings which quickly degrates to minimum number of occasional visits.
There is always gap in the night hours though.

topic_model.R
Very simple script to generate topic model using lda.
Problems with this script:
1. http://stackoverflow.com/questions/14697218/how-to-check-frequency-weighting-in-a-term-document-matrix-in-topicmodels
=>
"The DTM in 'topicmodels' does not recognize a term frequency weighting that uses TF-IDF,
the work around was to use normal term-frequency weighting instead of TF-IDF, not ideal,
but previous Blei et al. (2003) suggest that using TF-IDF is not necessary for LDA."

So script only uses TF (weighting=weightTf).

2. number of terms (k) is picked at random (10), should be decided based on corpus,
there are various techniques for this.

3. the result terms are:

k = 10
"súd" , "rok" , "zápas", "zápas", "zákon", "mesto" "krajina", "rok", "gól", "cesta" 

k = 20
"nemocnica", "gól", "vláda", "súd", "rok", "gól", "voľba", "cesta", "výstava", "rok", "rok", "krajina", "zápas", "film""škola", "rok", "mesto", "auto", "rok", "zápas" 

Why are there repeating terms 'rok', 'zápas'?