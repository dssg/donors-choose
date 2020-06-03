### Running this project

#### Setup

1. Configure a fresh instance of the DonorsChoose database (ask @kit?)
2. Create a new python environment and install python prerequisites from requirements.txt:

        `pip install -r requirements.txt`
3. Run each of the sql files in precompute_queries against your database, starting with create_optimized_tables. These queries improve databse performance and generate several aggregated features.
4. Create a [database.yaml file](https://github.com/dssg/triage/blob/master/example/database.yaml) with your credentials.

#### How to use

1. Run [main.py](main.py). This will run the Triage experiment defined in [donors-choose-config.yaml](donors-choose-config.yaml).
2.