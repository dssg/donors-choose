import yaml
import logging

from datetime import datetime 
from sqlalchemy.engine.url import URL
from sqlalchemy.pool import NullPool

from triage.util.db import create_engine
from triage.component.timechop import Timechop
from triage.component.timechop.plotting import visualize_chops
from triage.component.architect.feature_generators import FeatureGenerator
from triage.experiments import MultiCoreExperiment, SingleThreadedExperiment


# import os
# os.chdir('donors-choose')
now = datetime.now()
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(name)-30s  %(asctime)s %(levelname)10s %(process)6d  %(filename)-24s  %(lineno)4d: %(message)s', '%d/%m/%Y %I:%M:%S %p')
fh = logging.FileHandler(f'triage_{now}.log', mode='w')
fh.setFormatter(formatter)
logger.addHandler(fh)

# creating database engine
dbfile = 'database.yaml'

with open(dbfile, "r") as f:
    dbconfig = yaml.safe_load(f)

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
#config_file = 'donors-choose-config.yaml'
config_file = 'donors-choose-config-small.yaml'
with open(config_file, 'r') as fin:
    config = yaml.safe_load(fin)

# generating temporal config plot
chopper = Timechop(**config['temporal_config'])

# We aren't interested in seeing the entire feature_start_time represented
# in our timechop plot. That would hide the interesting information. So we
# set it to equal label_start_time for the plot.

chopper.feature_start_time = chopper.label_start_time 

visualize_chops(chopper, save_target = 'triage_output/timechop.png')

# creating experiment object

experiment = MultiCoreExperiment(
    config = config,
    db_engine = db_engine,
    project_path = 's3://dsapp-education-migrated/donors-choose',
    n_processes=3,
    n_db_processes=2,
    replace=False,
    save_predictions=False
)

# experiment = SingleThreadedExperiment(
#     config = config,
#     db_engine = db_engine,
#     project_path = 's3://dsapp-education-migrated/donors-choose',
#     replace=False,
#     save_predictions=False
# )

#experiment.validate()
experiment.run()