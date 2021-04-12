CREATE TABLE optimized.time_series_features as (SELECT DISTINCT entity_id, date_posted FROM projects);
alter table optimized.time_series_features
    add constraint entity_match FOREIGN KEY(entity_id) REFERENCES projects (entity_id);
