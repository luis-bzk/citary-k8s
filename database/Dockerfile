FROM postgres:15

ENV POSTGRES_USER=root
ENV POSTGRES_PASSWORD=root
ENV POSTGRES_DB=my_database_pg

COPY sql/core.sql /docker-entrypoint-initdb.d/01-core.sql
COPY sql/billing.sql /docker-entrypoint-initdb.d/02-billing.sql