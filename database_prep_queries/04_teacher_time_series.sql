-- see district_time_series.sql for documentation on these big nasty queries
set role {role};

ALTER TABLE optimized.time_series_features
ADD COLUMN teacher_avg_donations_1yr NUMERIC,
ADD COLUMN teacher_funding_rate_1yr NUMERIC;

--teacher_avg_donations_1yr
WITH donation_totals AS (
	SELECT 
		p.entity_id, 
		sum(donation_to_project) as total_donations, 
		total_price_including_optional_support AS total_price,
		date_posted,
		teacher_acctid
	FROM optimized.projects p 
	LEFT JOIN optimized.donations d using(entity_id) 
	WHERE d.donation_timestamp < (p.date_posted 
		+ make_interval(years => 0, 
						months => 4, 
						weeks => 0, 	
						days => 0))
	GROUP BY p.entity_id, p.total_price_including_optional_support, p.date_posted, p.teacher_acctid
), 

avg_donations_summary AS (
	SELECT 
		p1.entity_id, 
		sum(total_donations) / count(DISTINCT d1.entity_id) as avg_donations
	FROM optimized.projects p1
	JOIN donation_totals d1 ON (
		p1.teacher_acctid = d1.teacher_acctid AND
		p1.date_posted > (d1.date_posted + make_interval(months => 4)) AND
		p1.date_posted < (d1.date_posted + make_interval(years => 1))
	)
	GROUP BY p1.entity_id
)

UPDATE optimized.time_series_features 
SET teacher_avg_donations_1yr = avg_donations_summary.avg_donations
FROM avg_donations_summary
WHERE time_series_features.entity_id = avg_donations_summary.entity_id;
	
--teacher_funding_rate_1yr
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
		teacher_acctid
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
		AND p.date_posted < (fp.date_posted + make_interval(years => 1))
		AND p.teacher_acctid = fp.teacher_acctid)
	GROUP BY p.entity_id
)

UPDATE optimized.time_series_features 
SET teacher_funding_rate_1yr = funding_rate_summary.funding_rate
FROM funding_rate_summary
WHERE time_series_features.entity_id = funding_rate_summary.entity_id;


--2 years
ALTER TABLE optimized.time_series_features
ADD COLUMN teacher_avg_donations_2yr NUMERIC,
ADD COLUMN teacher_funding_rate_2yr NUMERIC;

--teacher_avg_donations_2yr
WITH donation_totals AS (
	SELECT 
		p.entity_id, 
		sum(donation_to_project) as total_donations, 
		total_price_including_optional_support AS total_price,
		date_posted,
		teacher_acctid
	FROM optimized.projects p 
	LEFT JOIN optimized.donations d using(entity_id) 
	WHERE d.donation_timestamp < (p.date_posted 
		+ make_interval(years => 0, 
						months => 4, 
						weeks => 0, 	
						days => 0))
	GROUP BY p.entity_id, p.total_price_including_optional_support, p.date_posted, p.teacher_acctid
), 

avg_donations_summary AS (
	SELECT
		p1.entity_id, 
		sum(total_donations) / count(DISTINCT d1.entity_id) as avg_donations
	FROM optimized.projects p1
	JOIN donation_totals d1 ON (
		p1.teacher_acctid = d1.teacher_acctid AND
		p1.date_posted > (d1.date_posted + make_interval(months => 4)) AND
		p1.date_posted < (d1.date_posted + make_interval(years => 2))
	)
	GROUP BY p1.entity_id
)

UPDATE optimized.time_series_features 
SET teacher_avg_donations_2yr = avg_donations_summary.avg_donations
FROM avg_donations_summary
WHERE time_series_features.entity_id = avg_donations_summary.entity_id;
	
--teacher_funding_rate_2yr
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
		teacher_acctid
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
		AND p.teacher_acctid = fp.teacher_acctid)
	GROUP BY p.entity_id
)

UPDATE optimized.time_series_features 
SET teacher_funding_rate_2yr = funding_rate_summary.funding_rate
FROM funding_rate_summary
WHERE time_series_features.entity_id = funding_rate_summary.entity_id;


COMMIT;