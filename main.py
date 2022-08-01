import yaml

from sqlalchemy.engine.url import URL
from triage.util.db import create_engine
from sqlalchemy import create_engine as engine_creator
from triage.component.timechop import Timechop
from triage.component.timechop.plotting import visualize_chops
from triage.component.architect.feature_generators import FeatureGenerator
from triage.experiments import MultiCoreExperiment, SingleThreadedExperiment
import logging

from sqlalchemy.pool import NullPool

# import os
# os.chdir('donors-choose')

logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
fh = logging.FileHandler('triage.log', mode='w')
fh.setFormatter(formatter)
logger.addHandler(fh)

# creating database engine
dbfile = 'database.yaml'

dbconfig = yaml.load(open(dbfile), Loader=yaml.SafeLoader)
db_url = URL.create(
            'postgresql',
            host=dbconfig['host'],
            username=dbconfig['user'],
            database=dbconfig['db'],
            password=dbconfig['pass'],
            port=dbconfig['port'],
        )

# db_url = f"postgresql://{dbconfig['user']}:{dbconfig['pass']}@{dbconfig['host']}:{dbconfig['port']}/{dbconfig['db']}"
db_engine = create_engine(db_url, poolclass=NullPool)


# loading config file
# config_file = 'donors-choose-config.yaml'
config_file = 'donors-choose-config-small.yaml'
with open(config_file, 'r') as fin:
    config = yaml.load(fin, Loader=yaml.SafeLoader)

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
    n_processes=2,
    n_db_processes=2,
    replace=False
)

# experiment = SingleThreadedExperiment(
#     config = config,
#     db_engine = db_engine,
#     project_path = 's3://dsapp-education-migrated/donors-choose',
#     replace=True
# )

experiment.validate()
experiment.run()