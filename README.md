# # Module 1 Homework: Docker & SQL
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

```bash
Answer: db:5433
$docker-compose up 
$ docker ps
CONTAINER ID   IMAGE                   COMMAND                  CREATED              STATUS              PORTS                           NAMES
4e19b3373e11   postgres:17-alpine      "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:5433->5432/tcp          postgres
75642cebacea   dpage/pgadmin4:latest   "/entrypoint.sh"         About a minute ago   Up About a minute   443/tcp, 0.0.0.0:8080->80/tcp   pgadmin
(base)
```
##  Prepare Postgres
To load data into postgres, we preapred greendata_upload.ipynb 
We'll use the green taxi trips from October 2019:
https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2019-10.parquet
we used below dataset with zones:
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
