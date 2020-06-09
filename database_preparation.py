'''
Script that executes database initialization files against 
configured database instance configured in database.yaml.
'''

import os
import yaml

from sqlalchemy.engine.url import URL
from triage.util.db import create_engine

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

queries = sorted(os.listdir('database_prep_queries'))

for file in queries:
    with open('database_prep_queries/' + file, 'r') as fin:
        query = fin.read()
    
    db_engine.execute(query)