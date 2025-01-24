#  Module 1 Homework: Docker & SQL
In this homework I have prepare the environment to practice Docker and SQL

## Question 1: 
### Run docker with the python:3.12.8 image in an interactive mode, use the entrypoint bash. What's the version of pip in the image?
Answer: 
```{sh}
$ docker run -it --entrypoint=bash python:3.12.8 
root@f9bf0439ffa2:/# pip --version
pip 24.3.1 from /usr/local/lib/python3.12/site-packages/pip (python 3.12)
$ docker ps -a
CONTAINER ID   IMAGE           COMMAND   CREATED         STATUS                      PORTS     NAMES
f9bf0439ffa2   python:3.12.8   "bash"    4 minutes ago   Exited (0) 20 seconds ago             brave_haibt
```
## Question 2: 
### Given the following docker-compose.yaml, what is the hostname and port that pgadmin should use to connect to the postgres database?
Answer: docker-compose.yaml file was created with below details:
```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```
Answer: db:5433

```bash
$docker-compose up 
$ docker ps
CONTAINER ID   IMAGE                   COMMAND                  CREATED              STATUS              PORTS                           NAMES
4e19b3373e11   postgres:17-alpine      "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:5433->5432/tcp          postgres
75642cebacea   dpage/pgadmin4:latest   "/entrypoint.sh"         About a minute ago   Up About a minute   443/tcp, 0.0.0.0:8080->80/tcp   pgadmin
(base)
```
##  Prepare Postgres
To load data into postgres, we preapred **greendata_upload.ipynb** 

We'll use the green taxi trips from October 2019 as mentioned in the homework and it can be downloded as either parquet or in csv:
```
https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2019-10.parquet
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
```
we used below dataset with zones details:
```
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```
## CLI for Postgres
Installing pgcli
```{sh}
conda install -c conda-forge pgcli
pip install -U mycli
```
Using pgcli to connect to Postgres
```{sh}
$ pgcli -h localhost -p 5433 -u postgres -d ny_taxi
Password for postgres:****
Server: PostgreSQL 17.2
Version: 4.1.0
Home: http://pgcli.com
```
## Querying the database
### Question 3. Trip Segmentation Count
During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, respectively, happened:
```{sql}
SELECT
    SUM(CASE WHEN trip_distance <= 1 THEN 1 ELSE 0 END) AS "Up to 1 mile",
    SUM(CASE WHEN trip_distance > 1 AND trip_distance <= 3 THEN 1 ELSE 0 END) AS "Between 1 and 3 miles",
    SUM(CASE WHEN trip_distance > 3 AND trip_distance <= 7 THEN 1 ELSE 0 END) AS "Between 3 and 7 miles",
    SUM(CASE WHEN trip_distance > 7 AND trip_distance <= 10 THEN 1 ELSE 0 END) AS "Between 7 and 10 miles",
    SUM(CASE WHEN trip_distance > 10 THEN 1 ELSE 0 END) AS "Over 10 miles"
FROM green_taxi_data
WHERE lpep_pickup_datetime >= '2019-10-01' AND lpep_pickup_datetime < '2019-11-01';
```
*Result:
Up to 1 mile	: 104830  \
Between 1 and 3 miles: 198995  \	
Between 3 and 7 miles: 109642	\
Between 7 and 10 miles: 27686	\
Over 10 miles: 35201

### Question 4. Longest trip for each day
Which was the pick up day with the longest trip distance? Use the pick up time for your calculations.
```{sql}
SELECT
    lpep_pickup_datetime::date AS pickup_day,
    MAX(trip_distance) AS max_distance
FROM green_taxi_data
GROUP BY pickup_day
ORDER BY max_distance DESC
LIMIT 1;
```
Result
pickup_day	max_distance  \
10/31/2019	515.89  \
### Question 5. Three biggest pickup zones
Which were the top pickup locations with over 13,000 in total_amount (across all trips) for 2019-10-18? Consider only lpep_pickup_datetime when filtering by date.
First the table columns are renamed 
```{sql}
ALTER TABLE green_taxi_data RENAME COLUMN "PULocationID" TO pulocationid;
ALTER TABLE green_taxi_data RENAME COLUMN "DOLocationID" TO dolocationid;
ALTER TABLE taxizone_data RENAME COLUMN "LocationID" TO locationid;
ALTER TABLE taxizone_data RENAME COLUMN "Borough" TO borough;
ALTER TABLE taxizone_data RENAME COLUMN "Zone" TO zone;
```
Then, table was joined with zone lookup table
```{sql}
SELECT
	z.borough,
	z.zone,
	SUM(g.total_amount) as total_amount
FROM green_taxi_data g
JOIN taxizone_data z ON g.pulocationID = z.locationID
WHERE g.lpep_pickup_datetime::date='2019-10-18'
GROUP BY 1,2
HAVING SUM(g.total_amount)>13000
ORDER BY total_amount DESC;
```
Result:
borough	             zone	         total_amount   \
Manhattan	 East Harlem North	  18686.68     \
Manhattan	 East Harlem South	  16797.26     \
Manhattan  Morningside Heights	13029.79

### Question 6. Largest tip
For the passengers picked up in October 2019 in the zone named "East Harlem North" which was the drop off zone that had the largest tip?
```{sql}
SELECT
    z_dropoff.zone AS dropoff_zone,
    MAX(g.tip_amount) AS max_tip
FROM green_taxi_data g
JOIN taxizone_data z_pickup ON g.pulocationid = z_pickup.locationid
JOIN taxizone_data z_dropoff ON g.dolocationid = z_dropoff.locationid
WHERE z_pickup.zone = 'East Harlem North'
AND g.lpep_pickup_datetime >= '2019-10-01'
AND g.lpep_pickup_datetime < '2019-11-01'
GROUP BY z_dropoff.zone
ORDER BY max_tip DESC
LIMIT 1;
```
Result:
dropoff_zone	   max_tip   \
JFK Airport	     87.3    \

### Question 7. Terraform Workflow 
Which of the following sequences, respectively, describes the workflow for:

Answer: terraform init, terraform apply -auto-approve, terraform destroy

Execution: created GCP project and service account with appropraite permissions.
Credential Access keys downloaded in Json format and saved locally.

# Refresh service-account's auth-token for this session
```
export GOOGLE_APPLICATION_CREDENTIALS="D:\DEZommcamp2025\gcp-serviceaccount\gcp_credentials.json"
gcloud auth application-default login
```
# Initialize state file (.tfstate)
```
terraform init
```
# Check changes to new infra plan
```
terraform plan -var="project=<your-gcp-project-id>"
```
# Create new infra
```
terraform apply -var="project=<your-gcp-project-id>"
```
# Delete infra after your work, to avoid costs on any running services
```
terraform destroy
```
Reference: **terraform-gcp Folder**
Explaination: 
- terraform init: Initializes the Terraform working directory and sets up the necessary plugins and configurations.
- terraform apply -auto-approve: Provisions the infrastructure as defined in the configuration files without requiring manual approval.
- terraform destroy: Destroys all the resources managed by Terraform, cleaning up the infrastructure.

## Learning public links
- 1.https://developer.hashicorp.com/terraform
- 2.https://developer.hashicorp.com/terraform/tutorials/gcp-get-started
- 3.https://docs.docker.com/manuals/
- 4.https://www.youtube.com/watch?v=18jIzE41fJ4&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=3
- 5.https://www.freecodecamp.org/news/postgresql-in-python/
