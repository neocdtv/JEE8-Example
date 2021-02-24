package io.neocdtv.jee8.app;

import io.neocdtv.jee8.app.boundary.EmployeeResource;
import io.neocdtv.jee8.app.boundary.PersonResource;
import io.neocdtv.jee8.app.boundary.StatusResource;
import org.glassfish.jersey.server.ServerProperties;

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
    classes.add(EmployeeResource.class);
    return classes;
  }


  @Override
  public Map<String, Object> getProperties() {
    final Map<String, Object> properties = new HashMap<>();
    /*
      config which may speed up deployment
     */
    properties.put(ServerProperties.METAINF_SERVICES_LOOKUP_DISABLE, true);
    properties.put(ServerProperties.FEATURE_AUTO_DISCOVERY_DISABLE, true);
    properties.put(ServerProperties.RESOURCE_VALIDATION_DISABLE, true);
    properties.put(ServerProperties.PROVIDER_SCANNING_RECURSIVE, false);
    return properties;
  }
}
