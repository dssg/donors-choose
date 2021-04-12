ALTER TABLE projects SET SCHEMA optimized;
ALTER TABLE projects RENAME COLUMN total_price_excluding_optional_support TO total_asking_price;
ALTER TABLE resources SET SCHEMA optimized;
CREATE TABLE optimized.essays AS SELECT entity_id, essay, date_posted FROM optimized.projects;