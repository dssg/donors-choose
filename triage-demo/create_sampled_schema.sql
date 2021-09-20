set role rg_staff;

drop schema if exists sampled_new cascade;

create schema sampled_new;

create table sampled_new.projects (like optimized.projects including all);

create table sampled_new.donations (like optimized.donations including all);

create table sampled_new.essays (like optimized.essays including all);

create table sampled_new.resources (like optimized.resources including all);

create table sampled_new.outcomes (like optimized.outcomes including all);

create table sampled_new.time_series_features (like optimized.time_series_features including all);

-- Sampling schools and projects
insert into sampled_new.projects 
(
    with schools as (
    select 
        distinct schoolid 
    from optimized.projects
),
sampled_schools as (
    select * from schools order by random() limit 1425
)
select 
    *
from sampled_schools join optimized.projects using(schoolid)
);


-- Fetching all donations from the sampled projects
insert into sampled_new.donations 
(
    select b.* from sampled_new.projects a join optimized.donations b using(entity_id)
); 

-- Fetching the precomputed features for the sampled projects
insert into sampled_new.time_series_features  (
    select b.* from sampled_new.projects a join optimized.time_series_features b using(entity_id, date_posted) 
); 

-- Essays of the sampled projects
insert into sampled_new.essays
(
    select b.* from sampled_new.projects a join optimized.essays b using(entity_id)   
);

insert into sampled_new.resources
(
    select b.* from sampled_new.projects join optimized.resources b using(entity_id, date_posted)
);

insert into sampled_new.outcomes 
(
    select b.* from sampled_new.projects join optimized.outcomes b using(entity_id)
);

commit;
