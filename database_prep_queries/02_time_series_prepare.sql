CREATE TABLE optimized.time_series_features as (SELECT DISTINCT entity_id, date_posted FROM optimized.projects)
alter table optimized.time_series_features
    add constraint FOREIGN KEY(entity_id) REFERENCES optimized.projects (entity_id)
