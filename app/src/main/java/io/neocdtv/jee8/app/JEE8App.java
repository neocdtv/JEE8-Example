package io.neocdtv.jee8.app;

import org.glassfish.jersey.server.ServerProperties;
import org.h2.tools.Server;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

@ApplicationPath("/")
public class JEE8App extends Application {

  @Override
  public Set<Class<?>> getClasses() {
    final Set<Class<?>> classes = new HashSet<>();
    classes.add(PersonResource.class);
    classes.add(StatusResource.class);
    return classes;
  }

  /*
  @Override
  public Map<String, Object> getProperties() {
    final Map<String, Object> properties = new HashMap<>();
    properties.put(ServerProperties.METAINF_SERVICES_LOOKUP_DISABLE, true);
    properties.put(ServerProperties.FEATURE_AUTO_DISCOVERY_DISABLE, true);
    properties.put(ServerProperties.RESOURCE_VALIDATION_DISABLE, true);
    properties.put(ServerProperties.PROVIDER_SCANNING_RECURSIVE, false);
    return properties;
  }
  */
}
