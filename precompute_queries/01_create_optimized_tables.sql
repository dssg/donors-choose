-- creates a optimized copy of the public schema:
-- 
-- changes projectid to an int key
-- 
-- sets projectid as projects primary key & donations foreign key
-- for indexes

DROP TABLE if exists optimized.donations;
DROP TABLE if exists optimized.projects;
DROP TABLE if exists optimized.ESSAYS;
DROP TABLE IF EXISTS optimized.resources;
DROP TABLE IF EXISTS optimized.outcomes;

DROP SCHEMA if exists optimized;

CREATE SCHEMA optimized;

GRANT ALL PRIVILEGES ON SCHEMA optimized TO rg_staff;

ALTER DEFAULT PRIVILEGES IN SCHEMA optimized GRANT ALL PRIVILEGES ON TABLES TO rg_staff;
ALTER DEFAULT PRIVILEGES IN SCHEMA optimized GRANT USAGE          ON SEQUENCES TO rg_staff;

CREATE TABLE optimized.projects AS (SELECT * FROM public.projects);
CREATE TABLE optimized.donations AS (SELECT * FROM public.donations);
CREATE TABLE optimized.essays AS (SELECT * FROM public.essays);
CREATE TABLE optimized.outcomes AS (SELECT * FROM public.outcomes);
CREATE TABLE optimized.resources AS (SELECT * FROM public.resources);

-- creating int projectid in projects

ALTER TABLE optimized.projects
	RENAME projectid TO projectid_str;

-- projectid_str_short for quicker joins when updating other tables

ALTER TABLE optimized.PROJECTS
	ADD COLUMN projectid_str_short varchar;

UPDATE optimized.PROJECTS 
	SET projectid_str_short = substring(projectid_str FROM 1 FOR 10);

ALTER TABLE OPTIMIZED.projects
	ADD COLUMN projectid serial NOT NULL PRIMARY KEY;

-- updating projectid in donations
ALTER TABLE optimized.donations
	RENAME COLUMN projectid TO projectid_str;

ALTER TABLE optimized.donations
	ADD COLUMN projectid_str_short varchar;

UPDATE optimized.donations
	SET projectid_str_short = substring(projectid_str FROM 1 FOR 10);

ALTER TABLE optimized.donations
	ADD COLUMN projectid integer;
	
UPDATE optimized.donations
	SET projectid = projects.projectid
	FROM optimized.PROJECTS 
	WHERE donations.projectid_str_short = projects.projectid_str_short;

-- essays
ALTER TABLE optimized.essays
	RENAME COLUMN projectid TO projectid_str;

ALTER TABLE optimized.essays
	ADD COLUMN projectid_str_short varchar;

UPDATE optimized.essays
	SET projectid_str_short = substring(projectid_str FROM 1 FOR 10);

ALTER TABLE optimized.essays
	ADD COLUMN projectid integer;
	
UPDATE optimized.essays
	SET projectid = projects.projectid
	FROM optimized.PROJECTS 
	WHERE essays.projectid_str_short = projects.projectid_str_short;

-- resources
ALTER TABLE optimized.resources
	RENAME COLUMN projectid TO projectid_str;

ALTER TABLE optimized.resources
	ADD COLUMN projectid_str_short varchar;

UPDATE optimized.resources
	SET projectid_str_short = substring(projectid_str FROM 1 FOR 10);

ALTER TABLE optimized.resources
	ADD COLUMN projectid integer;
	
UPDATE optimized.resources
	SET projectid = projects.projectid
	FROM optimized.PROJECTS 
	WHERE resources.projectid_str_short = projects.projectid_str_short;

-- outcomes
ALTER TABLE optimized.outcomes
	RENAME COLUMN projectid TO projectid_str;

ALTER TABLE optimized.outcomes
	ADD COLUMN projectid_str_short varchar;

UPDATE optimized.outcomes
	SET projectid_str_short = substring(projectid_str FROM 1 FOR 10);

ALTER TABLE optimized.outcomes
	ADD COLUMN projectid integer;
	
UPDATE optimized.outcomes
	SET projectid = projects.projectid
	FROM optimized.PROJECTS 
	WHERE outcomes.projectid_str_short = projects.projectid_str_short;

ALTER TABLE optimized.projects DROP COLUMN projectid_str_short;
ALTER TABLE optimized.donations DROP COLUMN projectid_str_short;
ALTER TABLE optimized.essays DROP COLUMN projectid_str_short;
ALTER TABLE optimized.resources DROP COLUMN projectid_str_short;
ALTER TABLE optimized.outcomes DROP COLUMN projectid_str_short;

ALTER TABLE optimized.projects DROP CONSTRAINT projects_pkey CASCADE;

ALTER TABLE optimized.projects ADD PRIMARY KEY (projectid);
ALTER TABLE optimized.donations ADD CONSTRAINT donations_fkey FOREIGN KEY (projectid) REFERENCES optimized.projects (projectid);
