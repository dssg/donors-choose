## Introduction

### DonorsChoose

[DonorsChoose](https://www.donorschoose.org/) is a nonprofit that addresses the education funding gap through crowdfunding. Since 2000, they have facilitated $970 million in donations to 40 million students in the United States.

However, approximately one third of all projects posted on DonorsChoose do not reach their funding goal within four months of posting.

This project will help DonorsChoose shrink the education funding gap by ensuring that more projects reach their funding goals. We will create an early warning system that identifies newly-posted projects that are likely to fail to meet their funding goals, allowing DonorsChoose to target those projects with an intervention such as a donation matching grant.

### The DonorsChoose Database

The donorschoose database contains 5 tables:

| Name          | Description                                                                                                                                                | Primary Key | Used? |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|-------|
| **projects**  | Basic metadata including teacher, class, and school information, and project asking price.                                                                 | projectid   | yes   |
| **resources** | Information about the classroom supply or tool the classroom is seeking funding for. Product category, per-unit price, quantity requested, etc.            | projectid   | yes   |
| **essays**    | Stores text of funding request.                                                                                                                            | projectid   | yes   |
| **donations** | Table of donations. Donor information, donation amount, messages from donors. Zero to many rows per project.| donationid  | yes   |
| **outcomes**  | Table of post-project outcomes. This table contains information that would be unavailable at time of prediction in a real-world case, so it is unused.  | projectid   | no    |


## Initial Processing

We performed some initial processing of the source database to improve database performance and ensure compliance with Triage. These changes are stored in a copy of the source schema, called optimized.

### Renaming projectid to entity_id

Triage expects each feature and label row to be identified by a primary key called entity_id. For convenience, we renamed projectid (our entity primary key) to entity_id.

### Integer entity ids

We replaced the source database's string (postgres varchar(32)) projectid key with integer keys. Triage [requires integer entityids](https://dssg.github.io/triage/experiments/cohort-labels/#note-2), and integer keys will improve performance on joins and group operations.

### Primary & Foreign Key constraints

We create primary key constraints on projectid in all tables (and a foreign key constraint on donations.projectid). This improves performance by creating indexes on each of those columns.

## Problem Framing

Let's start by stating our qualitative understanding of the problem. Then, we'll translate that into a formal problem framing, using the language of the Triage experiment config file.

### Qualitative Framing

DonorsChoose wants to institute a program where a group of projects at risk of falling short on funding are selected to recieve extra support: enrollment in a matching grant program funded by DonorsChoose's corporate partners, and prominent placement on the DonorsChoose project discovery page.

Since these interventions have limited capacity (funding is limited, and only a few projects at a time can really benefit from extra promotion on the homepage), we will identify 50 projects posted each month that need extra support.

Once a DonorsChoose project has been posted, it can recieve donations for four months. If it doesn't reach its funding goal by then, it is considered unfunded.

Therefore, our goal is to identify a machine learning model that identifies the 50 projects posted each month that are most likely to fail to reach their funding goal by four months later.

### Triage Framing

#### Temporal Config

For this project. we're using data from the projects posted between September 1, 2011 and June 1, 2013. 

```
feature_start_time: '2011-09-01'
label_start_time: '2011-09-01'

feature_end_time: '2013-06-01'
label_end_time: '2013-06-01'
```

Each month, the previous month's data becomes availabe for training a new model. 

`model_update_frequency: '1month'`


> ask about this. Still don't quite understand the justification. Seems like 1 day is just the default value. But how to explain to audience?


Our model will make predictions once a month, on the previous month's unlabeled data. Our one month test set length reflects this.

`test_durations:['1month']`


Patterns in the DonorsChoose data can change significantly within a year. We use one-month training sets ensuring that our models are trained on recent data, and capture recent trends.

`max_training_histories: ['1month']`


A project's label can only be measured four months after it has been posting. This means that each project has a four month label timespan.

```
training_label_timespans: ['4month']
test_label_timespans: ['4month']
```

Here's our temporal config in a timechop diagram:

![timechop](triage_output/timechop.png)

Triage builds a 13th train/test set with data from just a few as_of_dates in September 2011 - we'll ignore models from that set in model selection.

#### Outcome

Under our framing, each project can have one of two outcomes:

- **Fully funded**: Total donations in the four months following posting were equal to or greater than the requested amount
- **Not fully funded**: Total donations in the four months following posting were less than the requested amount.

We generate our label with a query that sums total donations to each project, and calculates a binary variable representing whether the project went unfunded (`1`) or met its goal (`0`).

Our query is parameterized by triage over `label_timespan` (in our case, always four months) and `as_of_date` (used here to select all the projects posted on a given `as_of_date`).

```sql

WITH donation_totals AS 
    (SELECT projects.entity_id, 
    sum(case when donation_to_project is null then 0 else donation_to_project end) as total_donations, 
    total_asking_price AS total_price
    FROM optimized.projects 
    LEFT JOIN optimized.donations ON (donations.entity_id = projects.entity_id
                    and donations.donation_timestamp < (projects.date_posted 
        + interval '{label_timespan}'))
    WHERE projects.date_posted = '{as_of_date}'::date - interval '1day'
    GROUP BY projects.entity_id, projects.total_asking_price)
SELECT entity_id,
(total_donations < total_price)::int AS outcome  
FROM optimized.projects
RIGHT JOIN donation_totals using(entity_id)
```
unsure if I should put the query here? do I need to repeat this (and other config parameters) since they're also in the config file?

#### Metric

Since our intervention is resource-constrained and limited to 50 projects each month, we are concerned with minimizing false positives. We optimize our models for precision at top 50.

## Feature Generation

We implement two categories of features. The first are features that we read directly from the database, raw, or with only transformations. These include project metadata such as teacher and student demographic information, category and price of requested resource, essay length, and other variables.

These features can be generated exclusively within triage, without performing any manual transforms within the database.

The second category of features are temporal aggregations of historical donation information. These answer questions like "how did a posting teacher's previous projects perform?" and "how did previous projects at the originating school perform?"

_Specifically, these features calculate funding rate (rate of successful projects) and average total donations over the 1 or 2 years prior to posting, within the same school district or zip, or from the same teacher as a project in question. (revise)_

These aggregations would be too complex to perform with Triage's feature aggregation system. So we wrote a series of sql queries to generate these feature manually, and stored them in a table called `time_series_features`.

The DDL statements that create these features are stored in [precompute_queries](precompute_queries)

## Model Selection

We use Auditioner to manage model selection. Plotting precision@50_abs over time shows that our models are generally performing well. Performance ranges from ~0.5 to 0.8, well above the prior rate of ~0.3.

![precision@50_over_time](triage_output/metric_over_time_precision@50_abs.png)

Building a basic Auditioner model selection grid, it looks like variance-penalized average precision (penalty = 0.5) and best current precision minimize regret.

|Criteria|Average regret (precision @ 50_abs)|
|-|-|
|Variance-penalized average precision (0.5)|0.0819|
|Best current precision | 0.0789|
|Most frequently within .03 of best | 0.0909|

![regret_over_time](triage_output/regret_over_time_precision@50_abs.png)

Variance-penalized average precision seems like a safe choice. It performs only slightly worse than the best criteria, and allows us to ignore models that perform inconsistently.

This criteria selects three random forest model groups for the next period:

|                                         | max_depth | max_features | n_estimators | min_samples_split |
|-----------------------------------------|-----------|--------------|--------------|-------------------|
| RandomForestClassifier | 10        | 12           | 10000        | 50                |
| RandomForestClassifier | 10        | auto         | 5000         | 25                |
| RandomForestClassifier | 10        | log2         | 1000         | 25                |