import os
import pandas as pd
from sqlalchemy import create_engine

pwd = os.environ["MYSQL_PWD"]            # never hard-code passwords in a repo
engine = create_engine(f"mysql+pymysql://root:{pwd}@localhost:3306/fmcg_tower")
src = r"C:\path\to\train_sample.csv"     # edit

total = 0
for i, chunk in enumerate(pd.read_csv(src, chunksize=50_000)):
    chunk.to_sql("stg_sales", engine, if_exists="append", index=False, method="multi")
    total += len(chunk)
    print(f"chunk {i + 1} done, {total:,} rows loaded")
