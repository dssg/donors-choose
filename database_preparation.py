'''
Script that executes database initialization files against 
configured database instance configured in database.yaml.
'''

import os
import yaml

from sqlalchemy.engine import URL
from sqlalchemy import text
from triage.util.db import create_engine

dbfile = 'database.yaml'

with open(dbfile, "r") as f:
    dbconfig = yaml.safe_load(f)

db_url = URL.create(
            'postgresql+psycopg2',
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
    
    with db_engine.connect() as conn:
        conn.execute(text(query.format(role=dbconfig['role'])))



