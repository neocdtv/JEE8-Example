CREATE TABLE t_person (
  id BIGINT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  PRIMARY KEY (id)
);

CREATE TABLE t_address (
  id BIGINT NOT NULL,
  city TEXT,
  person_id BIGINT,
  PRIMARY KEY (id),
  FOREIGN KEY (person_id) REFERENCES t_person(id)
);

CREATE TABLE t_organisation (
  id BIGINT NOT NULL,
  name TEXT,
  PRIMARY KEY (id)
);

CREATE SEQUENCE sq_person START WITH 10 INCREMENT BY 10 CACHE 1;
CREATE SEQUENCE sq_address START WITH 10 INCREMENT BY 10 CACHE 1;
CREATE SEQUENCE sq_orgranisation START WITH 10 INCREMENT BY 10 CACHE 1;

