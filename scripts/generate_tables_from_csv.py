from google.cloud import bigquery

base_path = "/"
bq_project = "bigquerylearning-388012"
bq_dataset = "dbtlearn"
client = bigquery.Client()

file_table_name = {
    "listings": "raw_listings",
    "reviews": "raw_reviews",
    "hosts": "raw_hosts"
}

job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,
    skip_leading_rows=1,
    autodetect=True
)

for file_name, table_name in file_table_name.items():
    print(f"Generating {file_name} table....")
    file_path = f"{base_path}/resources/{file_name}.csv"

    with open(file_path, "rb") as source_file:
        job = client.load_table_from_file(
            source_file,
            f"{bq_project}.{bq_dataset}.{table_name}",
            job_config=job_config
        )

        job.result()