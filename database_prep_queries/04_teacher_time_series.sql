-- see district_time_series.sql for documentation on these big nasty queries

ALTER TABLE optimized.time_series_features
	ADD COLUMN teacher_avg_donations_1yr NUMERIC,
	ADD COLUMN teacher_funding_rate_1yr NUMERIC;

WITH donation_totals AS 
            (SELECT projects.entity_id, 
            		sum(donation_to_project) as total_donations, 
            		total_price_excluding_optional_support AS total_price,
            		date_posted,
            		teacher_acctid
            FROM projects 
            LEFT JOIN donations ON donations.entity_id = projects.entity_id 
            WHERE donations.donation_timestamp < (projects.date_posted 
                + make_interval(years => 0, 
                				months => 4, 
                                weeks => 0, 	
                                days => 0))
            GROUP BY projects.entity_id, projects.total_price_excluding_optional_support, projects.date_posted, projects.teacher_acctid
    ), avg_donations_summary AS (
			SELECT p1.entity_id, 
				   sum(total_donations) / count(DISTINCT d1.entity_id) as avg_donations
			FROM PROJECTS p1
				JOIN donation_totals d1 ON (
					p1.teacher_acctid = d1.teacher_acctid AND
					p1.DATE_POSTED > (d1.date_posted + make_interval(months => 4)) AND
					p1.DATE_POSTED < (d1.date_posted + make_interval(years => 1))
	)
			GROUP BY p1.entity_id)

UPDATE optimized.time_series_features 
	SET teacher_avg_donations_1yr = avg_donations_summary.avg_donations
	FROM avg_donations_summary
	WHERE time_series_features.entity_id = avg_donations_summary.entity_id;
	
WITH donation_totals AS 
        (SELECT projects.entity_id, sum(donation_to_project) as total_donations, 
        total_price_excluding_optional_support AS total_price
        FROM projects 
        LEFT JOIN donations ON donations.entity_id = projects.entity_id 
        WHERE donations.donation_timestamp < (projects.date_posted 
            + make_interval(years => 0, months => 4, 
                            weeks => 0, days => 0))
        GROUP BY projects.entity_id, projects.total_price_excluding_optional_support
    ), funded_projects AS (
        SELECT entity_id, total_donations >= total_price AS fully_funded, DATE_POSTED, teacher_acctid
        FROM projects
        LEFT JOIN donation_totals using(entity_id)
        ORDER BY projects.entity_id
    ), funding_rate_summary AS (
    	SELECT projects.entity_id, 
    	   (sum(CASE WHEN fully_funded THEN 1 ELSE 0 END)::decimal / count(funded_projects.entity_id)) AS funding_rate,
    	   sum(CASE WHEN fully_funded THEN 1 ELSE 0 END) AS funded,
    	   count(funded_projects.entity_id) AS total
	FROM projects
	JOIN funded_projects ON (projects.DATE_POSTED > (funded_projects.date_posted + make_interval(months => 4))
						 AND projects.DATE_POSTED < (funded_projects.date_posted + make_interval(years => 1))
						 AND projects.teacher_acctid = funded_projects.teacher_acctid)
	GROUP BY projects.entity_id
)

UPDATE optimized.time_series_features 
	SET teacher_funding_rate_1yr = funding_rate_summary.funding_rate
	FROM funding_rate_summary
	WHERE time_series_features.entity_id = funding_rate_summary.entity_id;

ALTER TABLE optimized.time_series_features
	ADD COLUMN teacher_avg_donations_2yr NUMERIC,
	ADD COLUMN teacher_funding_rate_2yr NUMERIC;

WITH donation_totals AS 
            (SELECT projects.entity_id, 
            		sum(donation_to_project) as total_donations, 
            		total_price_excluding_optional_support AS total_price,
            		date_posted,
            		teacher_acctid
            FROM projects 
            LEFT JOIN donations ON donations.entity_id = projects.entity_id 
            WHERE donations.donation_timestamp < (projects.date_posted 
                + make_interval(years => 0, 
                				months => 4, 
                                weeks => 0, 	
                                days => 0))
            GROUP BY projects.entity_id, projects.total_price_excluding_optional_support, projects.date_posted, projects.teacher_acctid
    ), avg_donations_summary AS (
			SELECT p1.entity_id, 
				   sum(total_donations) / count(DISTINCT d1.entity_id) as avg_donations
			FROM PROJECTS p1
				JOIN donation_totals d1 ON (
					p1.teacher_acctid = d1.teacher_acctid AND
					p1.DATE_POSTED > (d1.date_posted + make_interval(months => 4)) AND
					p1.DATE_POSTED < (d1.date_posted + make_interval(years => 2))
	)
			GROUP BY p1.entity_id)

UPDATE optimized.time_series_features 
	SET teacher_avg_donations_2yr = avg_donations_summary.avg_donations
	FROM avg_donations_summary
	WHERE time_series_features.entity_id = avg_donations_summary.entity_id;
	
WITH donation_totals AS 
        (SELECT projects.entity_id, sum(donation_to_project) as total_donations, 
        total_price_excluding_optional_support AS total_price
        FROM projects 
        LEFT JOIN donations ON donations.entity_id = projects.entity_id 
        WHERE donations.donation_timestamp < (projects.date_posted 
            + make_interval(years => 0, months => 4, 
                            weeks => 0, days => 0))
        GROUP BY projects.entity_id, projects.total_price_excluding_optional_support
    ), funded_projects AS (
        SELECT entity_id, total_donations >= total_price AS fully_funded, DATE_POSTED, teacher_acctid
        FROM projects
        LEFT JOIN donation_totals using(entity_id)
        ORDER BY projects.entity_id
    ), funding_rate_summary AS (
    	SELECT projects.entity_id, 
    	   (sum(CASE WHEN fully_funded THEN 1 ELSE 0 END)::decimal / count(funded_projects.entity_id)) AS funding_rate,
    	   sum(CASE WHEN fully_funded THEN 1 ELSE 0 END) AS funded,
    	   count(funded_projects.entity_id) AS total
	FROM projects
	JOIN funded_projects ON (projects.DATE_POSTED > (funded_projects.date_posted + make_interval(months => 4))
						 AND projects.DATE_POSTED < (funded_projects.date_posted + make_interval(years => 2))
						 AND projects.teacher_acctid = funded_projects.teacher_acctid)
	GROUP BY projects.entity_id
)

UPDATE optimized.time_series_features 
	SET teacher_funding_rate_2yr = funding_rate_summary.funding_rate
	FROM funding_rate_summary
	WHERE time_series_features.entity_id = funding_rate_summary.entity_id;
