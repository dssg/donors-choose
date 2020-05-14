import yaml

from sqlalchemy.engine.url import URL
from triage.util.db import create_engine
from triage.component.timechop import Timechop
from triage.component.timechop.plotting import visualize_chops

from triage.experiments import SingleThreadedExperiment

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

visualize_chops(chopper, save_target = 'images/test.png')

# creating experiment object
experiment = SingleThreadedExperiment(
    config = config,
    db_engine = db_engine,
    project_path = '/mnt/data/users/aaron/donors-choose/cache'
)

