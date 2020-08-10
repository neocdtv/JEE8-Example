package io.neocdtv.jee8.app;

import javax.annotation.sql.DataSourceDefinition;

@DataSourceDefinition(
    name = ExampleDataSource.JNDI,
    className = "org.postgresql.ds.PGSimpleDataSource",
    url = "jdbc:postgresql://${ENV=DB_HOST}:${ENV=DB_PORT}/${ENV=DB_NAME}",
    serverName = "${ENV=DB_HOST}", // workaround for https://github.com/payara/Payara/issues/4385
    user = "${ENV=DB_USER}",
    password = "${ENV=DB_PASS}",
    properties = {
        "fish.payara.connection-validation-method=custom-validation",
        "fish.payara.validation-classname=org.glassfish.api.jdbc.validation.PostgresConnectionValidation",
        "fish.payara.is-connection-validation-required=true",
        "fish.payara.connection-leak-timeout-in-seconds=5"
    }) // NOSONAR
public final class ExampleDataSource {

  public static final String JNDI = "java:global/jdbc/ExampleDataSource";

  private ExampleDataSource() {}

}
