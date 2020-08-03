FROM postgres:11-alpine
ENV POSTGRES_DB=exampledb
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV RESOURCE_USER=resuser
ENV CONNECT_USER=conuser
ENV RESOURCE_USER_PW=pw
ENV CONNECT_USER_PW=pw
ENV SCHEMA=exampleschema
COPY ./src/main/docker/ /docker-entrypoint-initdb.d/