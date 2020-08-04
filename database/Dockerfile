FROM postgres:11-alpine
ENV POSTGRES_DB=exampledb
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV RESOURCE_USER=res_user
ENV CONNECT_USER=con_user
ENV RESOURCE_PASS=pw
ENV CONNECT_PASS=pw
ENV SCHEMA=exampleschema
COPY ./src/main/docker/ /docker-entrypoint-initdb.d/
