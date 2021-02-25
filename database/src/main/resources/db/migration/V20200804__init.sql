CREATE TABLE t_employee (
  id         BIGINT NOT NULL,
  first_name TEXT,
  last_name  TEXT,
  PRIMARY KEY (id)
);

CREATE TABLE t_person (
  id         BIGINT NOT NULL,
  first_name TEXT,
  last_name  TEXT,
  PRIMARY KEY (id)
);

CREATE TABLE t_flat (
  id   BIGINT NOT NULL,
  size INTEGER,
  PRIMARY KEY (id)
);

CREATE TABLE t_address (
  id        BIGINT NOT NULL,
  city      TEXT,
  person_id BIGINT,
  flat_id   BIGINT,
  PRIMARY KEY (id),
  FOREIGN KEY (person_id) REFERENCES t_person (id),
  FOREIGN KEY (flat_id) REFERENCES t_flat (id)
);

CREATE TABLE t_organisation (
  id   BIGINT NOT NULL,
  name TEXT,
  PRIMARY KEY (id)
);

CREATE SEQUENCE sq_employee START WITH 100 INCREMENT BY 100;
CREATE SEQUENCE sq_person START WITH 100 INCREMENT BY 100;
CREATE SEQUENCE sq_address START WITH 10 INCREMENT BY 10;
CREATE SEQUENCE sq_orgranisation START WITH 100 INCREMENT BY 100;
CREATE SEQUENCE sq_flat START WITH 10 INCREMENT BY 10;

