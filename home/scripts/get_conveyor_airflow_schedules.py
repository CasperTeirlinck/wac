import datetime as dt
import json
import subprocess

import matplotlib.pyplot as plt
import pandas as pd
import polars as pl
import requests
from croniter import croniter

pl.Config.set_tbl_rows(1000)
pl.Config.set_tbl_cols(100)

environments = [
    "agiondev",
    "agionprd",
    "agodidev",
    "agodiprd",
    "ahovoksdev",
    "ahovoksprd",
    "beleidsdomeindev",
    "beleidsdomeinprd",
    "departementdev",
    "departementprd",
    "inspectiedev",
    "inspectieprd",
]


def get_dags(token: str) -> pl.DataFrame:
    dfs: list[pl.DataFrame] = []
    for env in environments:
        print(f"Getting DAGs for {env}")
        result = requests.get(
            f"https://app.conveyordata.com/environments/{env}/airflow/api/v1/dags",
            params={
                "limit": 100,
            },
            headers={
                "accept": "application/json",
                "Authorization": f"Bearer {token}",
            },
        )
        # TODO: call /details to figure out the timezone. for now assume UTC
        dfs.append(pl.from_dicts(result.json()["dags"]))

    return pl.concat(dfs)


def clean_dags(df: pl.DataFrame) -> pl.DataFrame:
    airflow_cron_map = {
        "@hourly": "0 * * * *",
        "@daily": "0 0 * * *",
        "@weekly": "0 0 * * 0",
        "@monthly": "0 0 1 * *",
        "@quarterly": "0 0 1 */3 *",
        "@yearly": "0 0 1 1 *",
        "@annually": "0 0 1 1 *",
        "@midnight": "0 0 * * *",
    }

    return (
        df.filter(pl.col("is_active"))
        .with_columns(
            pl.col("schedule_interval")
            .struct.rename_fields(["schedule_type", "schedule"])
            .struct.unnest(),
        )
        .with_columns(schedule=pl.col("schedule").replace(airflow_cron_map))
        .filter(pl.col("schedule_type") == "CronExpression")
        .filter(~pl.col("schedule").str.starts_with("@"))
        .filter(~pl.col("schedule").str.starts_with("AssessmentQ"))
        .filter(~pl.col("schedule").str.starts_with("Dataset"))
    )


def get_token() -> str:
    result = subprocess.run(
        ["conveyor", "auth", "get", "--output", "json", "--quiet"],
        capture_output=True,
        check=True,
        text=True,
    )

    return json.loads(result.stdout)["access_token"]


df = get_dags(get_token()).pipe(clean_dags)

print(df)

crons = df["schedule"].to_list()

t_start = dt.datetime.now().replace(second=0, microsecond=0)
t_end = t_start + dt.timedelta(days=1)

timestamps = []

for cron in crons:
    itr = croniter(cron, t_start)
    while True:
        next_time = itr.get_next(dt.datetime)
        if next_time > t_end:
            break
        timestamps.append(next_time + dt.timedelta(hours=2))

df = pd.DataFrame(timestamps, columns=["time"])
df["hour"] = df["time"].dt.hour

plt.figure(figsize=(10, 6))
df["hour"].value_counts().sort_index().plot(kind="bar")
plt.title("Distribution of Cron Job Executions per Hour")
plt.xlabel("Hour of Day [CET]")
plt.ylabel("Number of Executions")
plt.xticks(rotation=0)
plt.tight_layout()
plt.show()
