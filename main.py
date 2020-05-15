import yaml

from sqlalchemy.engine.url import URL
from triage.util.db import create_engine
from triage.component.timechop import Timechop
from triage.component.timechop.plotting import visualize_chops
from triage.component.architect.feature_generators import FeatureGenerator
from triage.experiments import MultiCoreExperiment

import os
os.chdir('donors-choose')

# creating database engine
dbfile = 'database.yaml'

dbconfig = yaml.load(open(dbfile))
db_url = URL(
            'postgres',
            host=dbconfig['host'],
            username=dbconfig['user'],
            database=dbconfig['db'],
            password=dbconfig['pass'],
            port=dbconfig['port'],
        )

db_engine = create_engine(db_url)

# loading config file

with open('donors-choose-config.yaml', 'r') as fin:
    config = yaml.load(fin)

# generating temporal config plot
# chopper = Timechop(**config['temporal_config'])

# visualize_chops(chopper, save_target = 'images/test.png')

# creating experiment object
# experiment = MultiCoreExperiment(
#     config = config,
#     db_engine = db_engine,
#     project_path = '/mnt/data/users/aaron/donors-choose/cache',
#     n_processes=4,
#     n_db_processes=4,
#     replace=False
#     )

# experiment.run()


with open('donors-choose-config.yaml', 'r') as fin:
    config = yaml.load(fin)


feature_config = config['feature_aggregations']

FeatureGenerator(db_engine, 'features_test').create_features_before_imputation(
    feature_aggregation_config=feature_config,
    feature_dates=['2013-01-01'],
    state_table='(select entity_id, date_posted as as_of_date from optimized.projects)'
)


