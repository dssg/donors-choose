CREATE SCHEMA optimized;

CREATE TABLE projects (
    entity_id SERIAL NOT NULL PRIMARY KEY,

    project_id VARCHAR(32),
    schoolid VARCHAR(32),
    teacher_acctid VARCHAR(32),

    total_price_excluding_optional_support NUMERIC,
    grade_level TEXT,
    resource_type TEXT,

    essay TEXT,

    school_zip VARCHAR(32),
    school_state VARCHAR(32),
    school_metro VARCHAR(32),
    poverty_level VARCHAR(32),

    teacher_prefix TEXT,

    date_posted TIMESTAMP WITHOUT TIME ZONE
);

INSERT 
    INTO 
        projects (
            project_id,
            schoolid,
            teacher_acctid,
            total_price_excluding_optional_support,
            grade_level,
            resource_type,
            essay,
			date_posted
        )
    SELECT
        project_id,
        school_id,
        teacher_id,
        project_cost,
        project_grade_level_category,
        SUBSTRING(project_resource_category, 0, 8),
        project_essay,
        project_posted_date
    FROM
        raw.projects;

    
-- Dedupe
DELETE 
    FROM 
        projects a 
    USING 
        projects b 
    WHERE 
        a.entity_id > b.entity_id AND a.project_id = b.project_id;


-- Add schoold information    
UPDATE
    projects
SET
    school_zip = schools.school_zip,
    school_state = SUBSTRING(schools.school_state, 0, 8),
	poverty_level = 
		CASE
			WHEN schools.school_percentage_free_lunch < 10 THEN 'LOW'
			WHEN schools.school_percentage_free_lunch >= 10 AND schools.school_percentage_free_lunch < 40 THEN 'MODERATE'
			WHEN schools.school_percentage_free_lunch >= 40 AND schools.school_percentage_free_lunch < 65 THEN 'HIGH'
			ELSE 'HIGHEST'
		END,
	school_metro = schools.school_metro_type
FROM
    raw.schools
WHERE
    projects.schoolid = schools.school_id;


-- Add teacher information
UPDATE
    projects
SET
    teacher_prefix = teachers.teacher_prefix
FROM
    raw.teachers
WHERE
    projects.teacher_acctid = teachers.teacher_id;


-- Donations
CREATE TABLE donations (
    entity_id INTEGER,
    donation_to_project NUMERIC,
    donation_timestamp TIMESTAMP
);


INSERT 
    INTO
        donations
    SELECT 
        projects.entity_id,
        donation_amount,
        donation_received_date
    FROM
        raw.donations JOIN projects ON
            raw.donations.project_id = projects.project_id;


-- Resources
CREATE TABLE resources (
    entity_id INTEGER,
    item_unit_price NUMERIC,
    item_quantity NUMERIC,
    date_posted TIMESTAMP WITHOUT TIME ZONE
);


INSERT 
    INTO 
        resources
    SELECT
        projects.entity_id,
        resource_unit_price,
        resource_quantity,
        projects.date_posted
    FROM
        raw.resources JOIN projects ON
            raw.resources.project_id = projects.project_id;