FROM payara/micro:jdk11
COPY target/app.war $DEPLOY_DIR
CMD ["--deploymentDir", "/opt/payara/deployments", "--contextroot", "/", "--nocluster"]
