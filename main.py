import yaml

from sqlalchemy.engine.url import URL
from triage.util.db import create_engine
from triage.component.timechop import Timechop
from triage.component.timechop.plotting import visualize_chops
from triage.component.architect.feature_generators import FeatureGenerator
from triage.experiments import MultiCoreExperiment
import logging

import os
os.chdir('donors-choose')

logging.basicConfig(level=logging.INFO, 
                    filename = 'triage.log',
                    filemode='a',
                    format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
                    datefmt='%H:%M:%S')

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
    n_processes=32,
    n_db_processes=4,
    replace=False
    )

experiment.run()