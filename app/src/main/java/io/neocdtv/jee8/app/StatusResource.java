package io.neocdtv.jee8.app;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.core.Response;

@Path("status")
public class StatusResource {

  @GET
  public Response status() {
    return Response.ok().build();
  }
}
