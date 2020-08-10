-- make sure the connect user can work the the tables
-- this script is run after the migration is finished
GRANT USAGE ON SCHEMA ${db.schema} to ${connect.user};
GRANT SELECT, INSERT, UPDATE, DELETE ON  ALL TABLES IN SCHEMA ${db.schema} TO ${connect.user};
GRANT SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA ${db.schema}  TO ${connect.user};

