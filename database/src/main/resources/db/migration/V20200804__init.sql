CREATE TABLE t_person (
  id BIGINT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  PRIMARY KEY (id)
);

CREATE SEQUENCE sq_person START WITH 1;
