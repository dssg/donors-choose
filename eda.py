import pandas as pd
import yaml
from datetime import datetime


from sqlalchemy.engine.url import URL
from triage.util.db import create_engine

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

projects_by_month = db_engine.execute('''
    select to_char(date_posted, 'YYYY-mm') as month, count(*)
    from optimized.projects
    group by to_char(date_posted, 'YYYY-mm')
''')

projects_by_month = pd.DataFrame(projects_by_month)
projects_by_month.columns = ['month', 'count']

projects_by_month.month = pd.to_datetime(projects_by_month.month, format = '%Y-%m')

ax = projects_by_month.plot(x = 'month', y = 'count')

ax.get_figure().savefig('triage_output/project_counts_by_month.png')