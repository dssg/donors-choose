-- This query calculates funding rate, and average funding per project, for all projects completed before 
-- a given project was started, at the same school district, within the last 1 and 2 years.
-- 
-- The other queries in this directory do the same, but per-teacher and zip code.

ALTER TABLE optimized.time_series_features
	ADD COLUMN district_avg_donations_1yr NUMERIC,
	ADD COLUMN district_funding_rate_1yr NUMERIC;

WITH donation_totals AS (
	SELECT 
		p.entity_id, 
		sum(donation_to_project) as total_donations, 
		total_price_including_optional_support AS total_price,
		date_posted,
		schoolid
	FROM optimized.projects p 
	LEFT JOIN optimized.donations d using(entity_id)
	WHERE d.donation_timestamp < (p.date_posted 
		+ make_interval(years => 0, 
						months => 4, 
						weeks => 0, 	
						days => 0))
	GROUP BY p.entity_id, p.total_price_including_optional_support, p.date_posted, p.schoolid
), 

avg_donations_summary AS (
	SELECT 
		p1.entity_id, 
		sum(total_donations) / count(DISTINCT d1.entity_id) as avg_donations
	FROM optimized.projects p1
	JOIN donation_totals d1 ON (
		p1.schoolid = d1.schoolid AND
		p1.DATE_POSTED > (d1.date_posted + make_interval(months => 4)) AND
		p1.DATE_POSTED < (d1.date_posted + make_interval(years => 1))
    )
	GROUP BY p1.entity_id
)

UPDATE optimized.time_series_features 
SET district_avg_donations_1yr = avg_donations_summary.avg_donations
FROM avg_donations_summary
WHERE time_series_features.entity_id = avg_donations_summary.entity_id;
	


WITH donation_totals AS (
	SELECT 
		p.entity_id, 
		sum(donation_to_project) as total_donations, 
		total_price_including_optional_support AS total_price
	FROM optimized.projects p 
	LEFT JOIN optimized.donations d using(entity_id) 
	WHERE d.donation_timestamp < (p.date_posted 
		+ make_interval(years => 0, months => 4, 
						weeks => 0, days => 0))
	GROUP BY p.entity_id, p.total_price_including_optional_support
), 

funded_projects AS (
	SELECT 
		entity_id, 
		total_donations >= total_price AS fully_funded, 
		date_posted, 
		schoolid
	FROM optimized.projects p
	LEFT JOIN donation_totals dt using(entity_id)
	ORDER BY p.entity_id
), 

funding_rate_summary AS (
	SELECT 
		p.entity_id, 
		(sum(CASE WHEN fully_funded THEN 1 ELSE 0 END)::decimal / count(fp.entity_id)) AS funding_rate,
		sum(CASE WHEN fully_funded THEN 1 ELSE 0 END) AS funded,
		count(fp.entity_id) AS total
	FROM optimized.projects p 
	JOIN funded_projects fp ON (p.date_posted > (fp.date_posted + make_interval(months => 4))
						 AND p.date_posted < (fp.date_posted + make_interval(years => 1))
						 AND p.schoolid = fp.schoolid)
	GROUP BY p.entity_id
)

UPDATE optimized.time_series_features 
SET district_funding_rate_1yr = funding_rate_summary.funding_rate
FROM funding_rate_summary
WHERE time_series_features.entity_id = funding_rate_summary.entity_id;

--2 years

ALTER TABLE optimized.time_series_features
ADD COLUMN district_avg_donations_2yr NUMERIC,
ADD COLUMN district_funding_rate_2yr NUMERIC;

WITH donation_totals AS (
	SELECT 
		p.entity_id, 
		sum(donation_to_project) as total_donations, 
		total_price_including_optional_support AS total_price,
		date_posted,
		schoolid
	FROM optimized.projects p 
	LEFT JOIN optimized.donations d using(entity_id) 
	WHERE d.donation_timestamp < (p.date_posted 
		+ make_interval(years => 0, 
						months => 4, 
						weeks => 0, 	
						days => 0))
	GROUP BY p.entity_id, p.total_price_including_optional_support, p.date_posted, p.schoolid
), 

avg_donations_summary AS (
	SELECT 
		p1.entity_id, 
		sum(total_donations) / count(DISTINCT d1.entity_id) as avg_donations
	FROM optimized.projects p1
	JOIN donation_totals d1 ON (
		p1.schoolid = d1.schoolid AND
		p1.date_posted > (d1.date_posted + make_interval(months => 4)) AND
		p1.date_posted < (d1.date_posted + make_interval(years => 2))
	)
	GROUP BY p1.entity_id
)

UPDATE optimized.time_series_features 
SET district_avg_donations_2yr = avg_donations_summary.avg_donations
FROM avg_donations_summary
WHERE time_series_features.entity_id = avg_donations_summary.entity_id;
	

WITH donation_totals AS (
	SELECT 
		p.entity_id, 
		sum(donation_to_project) as total_donations, 
        total_price_including_optional_support AS total_price
	FROM optimized.projects p 
	LEFT JOIN optimized.donations d using(entity_id) 
	WHERE d.donation_timestamp < (p.date_posted 
		+ make_interval(years => 0, months => 4, 
						weeks => 0, days => 0))
	GROUP BY p.entity_id, p.total_price_including_optional_support
), 

funded_projects AS (
	SELECT 
		entity_id, 
		total_donations >= total_price AS fully_funded, 
		date_posted, 
		schoolid
	FROM optimized.projects p
	LEFT JOIN donation_totals using(entity_id)
	ORDER BY p.entity_id
), 

funding_rate_summary AS (
	SELECT 
		p.entity_id, 
		(sum(CASE WHEN fully_funded THEN 1 ELSE 0 END)::decimal / count(fp.entity_id)) AS funding_rate,
		sum(CASE WHEN fully_funded THEN 1 ELSE 0 END) AS funded,
		count(fp.entity_id) AS total
	FROM optimized.projects p
	JOIN funded_projects fp ON (
		p.date_posted > (fp.date_posted + make_interval(months => 4))
		AND p.date_posted < (fp.date_posted + make_interval(years => 2))
		AND p.schoolid = fp.schoolid)
	GROUP BY p.entity_id
)

UPDATE optimized.time_series_features 
SET district_funding_rate_2yr = funding_rate_summary.funding_rate
FROM funding_rate_summary
WHERE time_series_features.entity_id = funding_rate_summary.entity_id;
