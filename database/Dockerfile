FROM postgres:11-alpine
COPY ./src/main/docker/ /docker-entrypoint-initdb.d/

COPY wrapper.sh /
RUN chmod +x /wrapper.sh
ENTRYPOINT ["/wrapper.sh"]
CMD ["postgres", "-c", "logging_collector=on", "-c", "log_directory=/logs", "-c", "log_filename=postgresql.log", "-c", "log_statement=all"]
EXPOSE 5432
