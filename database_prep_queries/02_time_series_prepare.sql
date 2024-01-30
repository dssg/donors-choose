CREATE TABLE optimized.time_series_features as (SELECT DISTINCT entity_id, date_posted FROM optimized.projects); 

alter table optimized.time_series_features
    ADD CONSTRAINT time_series_fkey FOREIGN KEY(entity_id) REFERENCES optimized.projects (entity_id);